export class BuildMenu {
    constructor() {
        this.visible = false;
        this.position = { x: 0, y: 0 };
        this.selectedSpot = null;
    }
    open(spot) { this.visible = true; this.selectedSpot = spot; }
    close() { this.visible = false; this.selectedSpot = null; }
}