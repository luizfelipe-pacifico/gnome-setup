// Widget de fotos na área de trabalho, como o de Fotos do Mac: um quadro arredondado sobre o
// papel de parede (atrás das janelas) que troca de foto com um esmaecimento suave.
// As fotos ficam em ~/.local/share/widget-fotos (o app Aparência copia já reduzidas, ~720 px,
// para gastar pouca RAM e disco). Clicar abre a foto no visualizador de imagens.
import Clutter from 'gi://Clutter';
import Gio from 'gi://Gio';
import GLib from 'gi://GLib';
import St from 'gi://St';

import * as Main from 'resource:///org/gnome/shell/ui/main.js';
import {Extension} from 'resource:///org/gnome/shell/extensions/extension.js';

const PASTA = GLib.build_filenamev([GLib.get_user_data_dir(), 'widget-fotos']);
const MARGEM = 32;
const FADE_MS = 900;
// O Shell guarda na memória cada foto já mostrada: o limite segura o gasto (fotos de ~600 px)
const LIMITE = 30;

export default class WidgetFotos extends Extension {
    enable() {
        this._settings = this.getSettings();
        this._fotos = [];
        this._indice = -1;

        this._quadro = new St.Widget({
            style_class: 'widget-fotos',
            reactive: true,
            layout_manager: new Clutter.BinLayout(),
        });
        // Duas camadas: a de cima esmaece por cima da de baixo a cada troca
        this._baixo = new St.Widget({style_class: 'widget-fotos-foto', x_expand: true, y_expand: true});
        this._cima = new St.Widget({style_class: 'widget-fotos-foto', x_expand: true, y_expand: true});
        this._quadro.add_child(this._baixo);
        this._quadro.add_child(this._cima);
        this._quadro.connect('button-release-event', () => {
            this._abrirAtual();
            return Clutter.EVENT_STOP;
        });
        Main.layoutManager._backgroundGroup.add_child(this._quadro);

        this._settings.connectObject(
            'changed::tamanho', () => this._posicionar(),
            'changed::canto', () => this._posicionar(),
            'changed::intervalo', () => this._agendar(),
            this);
        Main.layoutManager.connectObject('monitors-changed', () => this._posicionar(), this);

        GLib.mkdir_with_parents(PASTA, 0o755);
        this._monitor = Gio.File.new_for_path(PASTA).monitor_directory(Gio.FileMonitorFlags.NONE, null);
        this._monitor.connect('changed', () => this._recarregarDepois());

        this._posicionar();
        this._recarregar();
    }

    disable() {
        if (this._timer)
            GLib.source_remove(this._timer);
        if (this._recarga)
            GLib.source_remove(this._recarga);
        this._timer = this._recarga = null;
        this._monitor?.cancel();
        this._monitor = null;
        this._settings.disconnectObject(this);
        Main.layoutManager.disconnectObject(this);
        this._quadro.destroy();
        this._quadro = this._baixo = this._cima = null;
        this._settings = null;
    }

    _posicionar() {
        const lado = this._settings.get_uint('tamanho');
        const monitor = Main.layoutManager.primaryMonitor;
        if (!monitor)
            return;
        this._quadro.set_size(lado, lado);
        const canto = this._settings.get_string('canto');
        const topo = monitor.y + MARGEM + Main.panel.height;
        const x = canto.endsWith('esquerdo') ? monitor.x + MARGEM : monitor.x + monitor.width - lado - MARGEM;
        const y = canto.startsWith('superior') ? topo : monitor.y + monitor.height - lado - MARGEM * 3;
        this._quadro.set_position(x, y);
    }

    _recarregarDepois() {
        // Várias fotos chegam de uma vez: espera a cópia terminar antes de reler a pasta
        if (this._recarga)
            GLib.source_remove(this._recarga);
        this._recarga = GLib.timeout_add(GLib.PRIORITY_DEFAULT, 800, () => {
            this._recarga = null;
            this._recarregar();
            return GLib.SOURCE_REMOVE;
        });
    }

    _recarregar() {
        const fotos = [];
        const dir = GLib.Dir.open(PASTA, 0);
        let nome;
        while ((nome = dir.read_name()) !== null) {
            if (/\.(jpe?g|png|webp)$/i.test(nome))
                fotos.push(GLib.build_filenamev([PASTA, nome]));
        }
        dir.close();
        // Ordem embaralhada, como no Mac
        for (let i = fotos.length - 1; i > 0; i--) {
            const j = Math.floor(Math.random() * (i + 1));
            [fotos[i], fotos[j]] = [fotos[j], fotos[i]];
        }
        this._fotos = fotos.slice(0, LIMITE);
        this._indice = -1;
        this._quadro.visible = this._fotos.length > 0;
        this._baixo.style = this._cima.style = null;
        if (this._fotos.length)
            this._proxima(false);
        this._agendar();
    }

    _agendar() {
        if (this._timer)
            GLib.source_remove(this._timer);
        this._timer = null;
        if (this._fotos.length < 2)
            return;
        this._timer = GLib.timeout_add_seconds(GLib.PRIORITY_LOW, this._settings.get_uint('intervalo'), () => {
            this._proxima(true);
            return GLib.SOURCE_CONTINUE;
        });
    }

    _estilo(caminho) {
        const uri = Gio.File.new_for_path(caminho).get_uri();
        return `background-image: url("${uri}");`;
    }

    _proxima(animar) {
        this._indice = (this._indice + 1) % this._fotos.length;
        const estilo = this._estilo(this._fotos[this._indice]);
        if (!animar) {
            this._baixo.style = this._cima.style = estilo;
            return;
        }
        this._cima.remove_all_transitions();
        this._baixo.style = this._cima.style;
        this._cima.opacity = 0;
        this._cima.style = estilo;
        this._cima.ease({opacity: 255, duration: FADE_MS, mode: Clutter.AnimationMode.EASE_IN_OUT_QUAD});
    }

    _abrirAtual() {
        const foto = this._fotos[this._indice];
        if (foto)
            Gio.AppInfo.launch_default_for_uri(Gio.File.new_for_path(foto).get_uri(), null);
    }
}
