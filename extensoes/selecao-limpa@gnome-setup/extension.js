// Captura de tela sem a seleção anterior: ao fechar, a área some (fica 1 px no canto),
// então na próxima vez qualquer clique começa uma seleção nova, como no Mac.
import * as Main from 'resource:///org/gnome/shell/ui/main.js';
import {Extension} from 'resource:///org/gnome/shell/extensions/extension.js';

export default class SelecaoLimpa extends Extension {
    enable() {
        this._limpar();
        // 'closed' vem depois do GNOME restaurar a área antiga, então a limpeza ganha
        Main.screenshotUI.connectObject('closed', () => this._limpar(), this);
    }

    disable() {
        Main.screenshotUI.disconnectObject(this);
    }

    _limpar() {
        const area = Main.screenshotUI._areaSelector;
        if (!area)
            return;
        area._startX = area._lastX = 0;
        area._startY = area._lastY = 0;
        area._updateSelectionRect();
    }
}
