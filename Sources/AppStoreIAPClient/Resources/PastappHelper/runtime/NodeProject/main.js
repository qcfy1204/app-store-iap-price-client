import 'dotenv/config';
import {Ipa} from './src/ipa.js';
import {featuredApps, fetchVersions, lookupApp, searchApps} from './src/catalog.js';
import {emit, emitError} from './src/events.js';
import {t} from './src/i18n.js';

function requiredEnv(name) {
    const value = process.env[name];
    if (!value) {
        throw new Error(t('missing_config', {name}));
    }
    return value;
}

function parseArgs(argv) {
    const args = {};
    for (let i = 0; i < argv.length; i += 1) {
        const value = argv[i];
        if (!value.startsWith('--')) continue;

        const equalIndex = value.indexOf('=');
        if (equalIndex > -1) {
            args[value.slice(2, equalIndex)] = value.slice(equalIndex + 1);
            continue;
        }

        const key = value.slice(2);
        const next = argv[i + 1];
        if (next && !next.startsWith('--')) {
            args[key] = next;
            i += 1;
        } else {
            args[key] = 'true';
        }
    }
    return args;
}

function configureJsonEvents(args) {
    if (args['json-events'] === 'true') {
        process.env.PASTAPP_JSON_EVENTS = '1';
    }
}

function printJSON(value) {
    process.stdout.write(`${JSON.stringify(value)}\n`);
}

function collectDiagnosticFields(value, path = '', depth = 0, output = []) {
    if (!value || typeof value !== 'object' || depth > 8) return output;
    if (Array.isArray(value)) {
        value.slice(0, 5).forEach((item, index) => collectDiagnosticFields(item, `${path}[${index}]`, depth + 1, output));
        return output;
    }
    for (const [key, child] of Object.entries(value)) {
        const childPath = path ? `${path}.${key}` : key;
        if (/price|pricing|inapp|in-app|iap|subscription|offer|display/i.test(key)) {
            output.push({
                path: childPath,
                type: Array.isArray(child) ? 'array' : typeof child,
                preview: typeof child === 'string' || typeof child === 'number' || typeof child === 'boolean'
                    ? String(child).slice(0, 160)
                    : undefined,
            });
        }
        collectDiagnosticFields(child, childPath, depth + 1, output);
    }
    return output;
}

async function runCommand(command, args) {
    configureJsonEvents(args);
    switch (command) {
    case 'search': {
        const query = args.query || args.term || '';
        if (!query.trim()) throw new Error(t('missing_query'));
        const result = await searchApps(query, {
            country: args.country || 'cn',
            limit: Number(args.limit || 30),
        });
        printJSON(result);
        return;
    }
    case 'lookup': {
        const appId = args.id || args.appid || args.appId || '';
        if (!appId.trim()) throw new Error(t('missing_appid'));
        const result = await lookupApp(appId, {country: args.country || 'cn'});
        printJSON(result);
        return;
    }
    case 'featured': {
        const result = await featuredApps({
            country: args.country || 'cn',
            limit: Number(args.limit || 30),
            offset: Number(args.offset || 0),
        });
        printJSON(result);
        return;
    }
    case 'versions': {
        const appId = args.id || args.appid || args.appId || '';
        if (!appId.trim()) throw new Error(t('missing_appid'));
        const result = await fetchVersions(appId, {provider: args.provider || 'auto'});
        printJSON(result);
        return;
    }
    case 'diagnose-iap': {
        const appId = args.id || args.appid || args.appId || '';
        const email = args.email || args.appleId || '';
        if (!appId.trim()) throw new Error(t('missing_appid'));
        if (!email.trim()) throw new Error(t('missing_config', {name: 'email'}));
        const app = new Ipa({APPLE_ID: email, PASSWORD: process.env.APPLE_PWD || '', CODE: process.env.APPLE_CODE || ''});
        await app.login();
        const appInfo = await app.info(appId, args.versionId || '');
        const metadata = appInfo?.metadata || {};
        printJSON({
            ok: true,
            appId: String(appId),
            storefront: String(app.user?.authHeaders?.['X-Apple-Store-Front'] || '').split('-')[0],
            topLevelKeys: Object.keys(appInfo || {}).sort(),
            metadataKeys: Object.keys(metadata).sort(),
            diagnosticFields: collectDiagnosticFields(appInfo || {}).slice(0, 200),
        });
        return;
    }
    case 'account-iap': {
        const appId = args.id || args.appid || args.appId || '';
        const email = args.email || args.appleId || '';
        const countryCode = String(args.country || '').trim().toUpperCase();
        if (!appId.trim()) throw new Error(t('missing_appid'));
        if (!email.trim()) throw new Error(t('missing_config', {name: 'email'}));
        const app = new Ipa({APPLE_ID: email, PASSWORD: process.env.APPLE_PWD || '', CODE: process.env.APPLE_CODE || ''});
        await app.login();
        const result = await app.accountIAPInfo(appId);
        const message = result.rows.length
            ? '已登录账户返回内购价格。'
            : (result.hasOrEverHasHadIAP
                ? '已登录账户元数据确认此 App 有内购，但未返回详细内购价格。'
                : '已登录账户元数据未返回详细内购价格。');
        printJSON({
            ok: true,
            appId: result.appId,
            appName: result.appName,
            storefront: result.storefront,
            countryCode,
            currencyCode: String(args.currency || '').trim().toUpperCase(),
            rows: result.rows,
            message,
        });
        return;
    }
    case 'logout': {
        const email = args.email || args.appleId || args.id || '';
        if (!email.trim()) throw new Error(t('missing_config', {name: 'email'}));
        const app = new Ipa({APPLE_ID: email, PASSWORD: '', CODE: ''});
        await app.clearSession();
        printJSON({ok: true});
        emit('done', {message: t('cleanup_done')});
        return;
    }
    default:
        throw new Error(t('unknown_command', {command}));
    }
}

(async () => {
    try {
        const command = process.argv[2];
        if (command) {
            await runCommand(command, parseArgs(process.argv.slice(3)));
            return;
        }

        const app = new Ipa({
            APPLE_ID: requiredEnv('APPLE_ID'),
            PASSWORD: requiredEnv('APPLE_PWD'),
            CODE: process.env.APPLE_CODE || '',
        });

        // 校验账户模式：强制全新登录（验证密码 + 一次 2FA），成功后回报账户所属商店地区。
        if (process.env.IPA_VALIDATE_LOGIN) {
            await app.login({force: true});
            const storefront = String(app.user?.authHeaders?.['X-Apple-Store-Front'] || '').split('-')[0];
            const addr = app.user?.accountInfo?.address || {};
            emit('account', {message: `账户地区：${storefront}`, storefront});
            printJSON({ok: true, storefront, firstName: addr.firstName || '', lastName: addr.lastName || ''});
            emit('done', {message: t('all_done')});
            console.log(t('all_done'));
            return;
        }

        await app.login();

        // 兜底模式：只登录并从 Apple 元数据取版本 ID 列表，不下载。
        if (process.env.IPA_LIST_VERSION_IDS) {
            const result = await app.listVersionIds(requiredEnv('DOWNLOAD_APPID'));
            printJSON(result);
            emit('done', {message: t('all_done')});
            console.log(t('all_done'));
            return;
        }

        await app.run({
            dir: process.env.DOWNLOAD_DIR || './app',
            APPID: requiredEnv('DOWNLOAD_APPID'),
            appVerId: process.env.DOWNLOAD_VERSION_ID || '',
        });

        emit('done', {message: t('all_done')});
        console.log(t('all_done'));
    } catch (err) {
        emitError(err);
        console.error(err.message || String(err));
        process.exit(1);
    }
})();
