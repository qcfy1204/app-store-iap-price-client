function enabled() {
    return process.env.PASTAPP_JSON_EVENTS === '1' || process.argv.includes('--json-events');
}

function emit(type, payload = {}) {
    if (!enabled()) return false;
    process.stdout.write(`${JSON.stringify({type, ...payload})}\n`);
    return true;
}

function emitError(error) {
    const message = error?.message || String(error);
    const code = error?.code || '';
    emit(code === 'NEEDS_2FA' ? 'needs_2fa' : 'error', {message, code});
}

export {enabled as jsonEventsEnabled, emit, emitError};
