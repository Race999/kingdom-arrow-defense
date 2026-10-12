export const STATES = {
    LOADING: 'loading',
    MENU: 'menu',
    PLAYING: 'playing',
    PAUSED: 'paused',
    VICTORY: 'victory',
    DEFEAT: 'defeat'
};

export class StateMachine {
    constructor() {
        this.current = STATES.LOADING;
        this.previous = null;
        this.listeners = new Map();
    }
    on(state, callback) {
        if (!this.listeners.has(state)) this.listeners.set(state, []);
        this.listeners.get(state).push(callback);
    }
    transition(newState) {
        if (this.current === newState) return;
        this.previous = this.current;
        this.current = newState;
        const callbacks = this.listeners.get(newState) || [];
        for (const cb of callbacks) cb(this.previous, newState);
    }
    is(state) { return this.current === state; }
}