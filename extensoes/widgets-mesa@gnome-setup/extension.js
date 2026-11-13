// Widgets na área de trabalho, como os do Mac: Relógio de ponteiros, Calendário (dia de hoje),
// Clima (a cidade escolhida no app Clima do GNOME) e Baterias (computador e aparelhos Bluetooth).
// Ficam numa coluna sobre o papel de parede, atrás das janelas. Cada um liga no app Aparência.
import Cairo from 'cairo';
import Clutter from 'gi://Clutter';
import Gio from 'gi://Gio';
import GLib from 'gi://GLib';
import St from 'gi://St';
import UPower from 'gi://UPowerGlib';

import * as Main from 'resource:///org/gnome/shell/ui/main.js';
import * as Weather from 'resource:///org/gnome/shell/misc/weather.js';
import {Extension} from 'resource:///org/gnome/shell/extensions/extension.js';

const MARGEM = 32;
const ESPACO = 16;
const WIDGETS = ['relogio', 'calendario', 'clima', 'baterias'];

// Aparelhos que mostram bateria, com o ícone de cada um
const APARELHOS = new Map([
    [UPower.DeviceKind.BATTERY, 'computer-symbolic'],
    [UPower.DeviceKind.MOUSE, 'input-mouse-symbolic'],
    [UPower.DeviceKind.KEYBOARD, 'input-keyboard-symbolic'],
    [UPower.DeviceKind.HEADSET, 'audio-headset-symbolic'],
    [UPower.DeviceKind.HEADPHONES, 'audio-headphones-symbolic'],
    [UPower.DeviceKind.GAMING_INPUT, 'input-gaming-symbolic'],
    [UPower.DeviceKind.PHONE, 'phone-symbolic'],
    [UPower.DeviceKind.TABLET, 'input-tablet-symbolic'],
    [UPower.DeviceKind.TOUCHPAD, 'input-touchpad-symbolic'],
    [UPower.DeviceKind.WEARABLE, 'watch-symbolic'],
]);

function cartao(...classes) {
    return new St.BoxLayout({
        style_class: ['widget-mesa', ...classes].join(' '),
        orientation: Clutter.Orientation.VERTICAL,
        reactive: true,
    });
}

function abrir(id) {
    Gio.DesktopAppInfo.new(`${id}.desktop`)?.launch([], null);
}

class Relogio {
    constructor(escuro) {
        this.actor = cartao('widget-mesa-relogio');
        this._escuro = escuro;
        this._area = new St.DrawingArea({x_expand: true, y_expand: true});
        this._area.connect('repaint', a => this._desenhar(a));
        this.actor.add_child(this._area);
        this.actor.connect('button-release-event', () => abrir('org.gnome.clocks'));
        this._timer = GLib.timeout_add_seconds(GLib.PRIORITY_DEFAULT, 1, () => {
            this._area.queue_repaint();
            return GLib.SOURCE_CONTINUE;
        });
    }

    _desenhar(area) {
        const cr = area.get_context();
        const [w, h] = area.get_surface_size();
        const r = Math.min(w, h) / 2;
        const escuro = this._escuro();
        const tinta = escuro ? [0.96, 0.96, 0.97] : [0.11, 0.11, 0.12];
        cr.translate(w / 2, h / 2);

        // Mostrador
        cr.arc(0, 0, r - 1, 0, 2 * Math.PI);
        cr.setSourceRGB(...(escuro ? [0.08, 0.08, 0.09] : [1, 1, 1]));
        cr.fill();

        // Números de 1 a 12
        cr.selectFontFace('Inter', Cairo.FontSlant.NORMAL, Cairo.FontWeight.BOLD);
        cr.setFontSize(r * 0.2);
        cr.setSourceRGB(...tinta);
        for (let n = 1; n <= 12; n++) {
            const ang = n * Math.PI / 6;
            const texto = String(n);
            const ext = cr.textExtents(texto);
            cr.moveTo(Math.sin(ang) * r * 0.76 - ext.width / 2 - ext.xBearing,
                -Math.cos(ang) * r * 0.76 - ext.height / 2 - ext.yBearing);
            cr.showText(texto);
        }

        const agora = GLib.DateTime.new_now_local();
        const seg = agora.get_second();
        const min = agora.get_minute() + seg / 60;
        const hora = (agora.get_hour() % 12) + min / 60;
        const ponteiro = (ang, comp, larg, cor) => {
            cr.save();
            cr.rotate(ang);
            cr.setSourceRGB(...cor);
            cr.setLineWidth(larg);
            cr.setLineCap(Cairo.LineCap.ROUND);
            cr.moveTo(0, r * 0.12);
            cr.lineTo(0, -comp);
            cr.stroke();
            cr.restore();
        };
        ponteiro(hora * Math.PI / 6, r * 0.45, r * 0.07, tinta);
        ponteiro(min * Math.PI / 30, r * 0.68, r * 0.05, tinta);
        ponteiro(seg * Math.PI / 30, r * 0.74, r * 0.02, [1, 0.58, 0]);
        cr.arc(0, 0, r * 0.045, 0, 2 * Math.PI);
        cr.setSourceRGB(1, 0.58, 0);
        cr.fill();
        cr.$dispose();
    }

    destroy() {
        GLib.source_remove(this._timer);
        this.actor.destroy();
    }
}

class Calendario {
    constructor() {
        this.actor = cartao();
        this._semana = new St.Label({style_class: 'widget-mesa-semana'});
        this._dia = new St.Label({style_class: 'widget-mesa-dia', y_expand: true,
            y_align: Clutter.ActorAlign.CENTER});
        this._mes = new St.Label({style_class: 'widget-mesa-mes'});
        this.actor.add_child(this._semana);
        this.actor.add_child(this._dia);
        this.actor.add_child(this._mes);
        this.actor.connect('button-release-event', () => abrir('org.gnome.Calendar'));
        this._atualizar();
        this._timer = GLib.timeout_add_seconds(GLib.PRIORITY_LOW, 60, () => {
            this._atualizar();
            return GLib.SOURCE_CONTINUE;
        });
    }

    _atualizar() {
        const hoje = GLib.DateTime.new_now_local();
        this._semana.text = hoje.format('%A').toUpperCase();
        this._dia.text = String(hoje.get_day_of_month());
        this._mes.text = hoje.format('%B');
    }

    destroy() {
        GLib.source_remove(this._timer);
        this.actor.destroy();
    }
}

class Clima {
    constructor() {
        this.actor = cartao('widget-mesa-clima');
        this._cidade = new St.Label({style_class: 'widget-mesa-cidade'});
        this._temp = new St.Label({style_class: 'widget-mesa-temp'});
        this._icone = new St.Icon({icon_size: 22, x_align: Clutter.ActorAlign.START});
        this._ceu = new St.Label({style_class: 'widget-mesa-ceu'});
        this._aviso = new St.Label({style_class: 'widget-mesa-aviso', y_expand: true,
            y_align: Clutter.ActorAlign.CENTER});
        this._aviso.clutter_text.line_wrap = true;
        for (const a of [this._cidade, this._temp, this._icone, this._ceu, this._aviso])
            this.actor.add_child(a);

        this._cliente = new Weather.WeatherClient();
        this._cliente.connectObject('changed', () => this._atualizar(), this);
        this.actor.connect('button-release-event', () => this._cliente.activateApp());
        this._cliente.update();
        this._timer = GLib.timeout_add_seconds(GLib.PRIORITY_LOW, 30 * 60, () => {
            this._cliente.update();
            return GLib.SOURCE_CONTINUE;
        });
        this._atualizar();
    }

    _mostrar(aviso) {
        this._aviso.visible = !!aviso;
        this._aviso.text = aviso ?? '';
        for (const a of [this._cidade, this._temp, this._icone, this._ceu])
            a.visible = !aviso;
    }

    _atualizar() {
        const c = this._cliente;
        if (!c.available)
            return this._mostrar('Instale o app Clima para ver o tempo aqui');
        if (!c.hasLocation)
            return this._mostrar('Abra o Clima e escolha a sua cidade');
        const info = c.info;
        if (c.loading && !info.is_valid())
            return this._mostrar('Carregando…');
        if (!info.is_valid())
            return this._mostrar(info.network_error() ? 'Sem internet' : 'Clima indisponível');
        this._mostrar(null);
        this._cidade.text = info.location.get_city_name() ?? info.get_location_name();
        this._temp.text = info.get_temp_summary().replace(/\s*°[CF]$/, '°');
        this._icone.icon_name = info.get_symbolic_icon_name();
        this._ceu.text = info.get_sky() || info.get_conditions();
        if (info.is_daytime())
            this.actor.remove_style_class_name('noite');
        else
            this.actor.add_style_class_name('noite');
    }

    destroy() {
        GLib.source_remove(this._timer);
        this._cliente.disconnectObject(this);
        this.actor.destroy();
    }
}

class Baterias {
    constructor(escuro) {
        this.actor = cartao();
        this._escuro = escuro;
        this._grade = new St.Widget({layout_manager: new Clutter.GridLayout({
            row_spacing: 12, column_spacing: 12}),
        x_align: Clutter.ActorAlign.CENTER, y_align: Clutter.ActorAlign.CENTER, x_expand: true, y_expand: true});
        this.actor.add_child(this._grade);
        this.actor.connect('button-release-event', () => abrir('gnome-power-panel'));
        this._aparelhos = [];
        this._cliente = UPower.Client.new_full(null);
        this._cliente.connectObject(
            'device-added', () => this._recarregar(),
            'device-removed', () => this._recarregar(), this);
        this._recarregar();
    }

    _recarregar() {
        for (const d of this._aparelhos)
            d.disconnectObject(this);
        this._grade.destroy_all_children();
        // get_devices2 entrega os aparelhos já liberados no gjs; get_devices funciona
        this._aparelhos = this._cliente.get_devices()
            .filter(d => APARELHOS.has(d.kind) && d.is_present && (d.kind !== UPower.DeviceKind.BATTERY || d.power_supply))
            .slice(0, 4);
        this._aparelhos.forEach((d, i) => {
            const area = new St.DrawingArea({x_expand: true, y_expand: true});
            area.connect('repaint', a => this._anel(a, d));
            const icone = new St.Icon({icon_name: APARELHOS.get(d.kind), icon_size: 18,
                x_align: Clutter.ActorAlign.CENTER, y_align: Clutter.ActorAlign.CENTER});
            const celula = new St.Widget({style_class: 'widget-mesa-anel', layout_manager: new Clutter.BinLayout(),
                x_align: Clutter.ActorAlign.CENTER, y_align: Clutter.ActorAlign.CENTER});
            celula.add_child(area);
            celula.add_child(icone);
            this._grade.layout_manager.attach(celula, i % 2, Math.floor(i / 2), 1, 1);
            d.connectObject('notify::percentage', () => area.queue_repaint(),
                'notify::state', () => area.queue_repaint(), this);
        });
        // Sem nada com bateria (computador de mesa sem Bluetooth): o widget some
        this.actor.visible = this._aparelhos.length > 0;
    }

    _anel(area, d) {
        const cr = area.get_context();
        const [w, h] = area.get_surface_size();
        const r = Math.min(w, h) / 2 - 4;
        const pct = Math.max(0, Math.min(100, d.percentage)) / 100;
        const carregando = d.state === UPower.DeviceState.CHARGING;
        cr.setLineWidth(5);
        cr.setLineCap(Cairo.LineCap.ROUND);
        cr.arc(w / 2, h / 2, r, 0, 2 * Math.PI);
        const trilho = this._escuro() ? 1 : 0;
        cr.setSourceRGBA(trilho, trilho, trilho, 0.15);
        cr.stroke();
        if (pct > 0) {
            cr.arc(w / 2, h / 2, r, -Math.PI / 2, -Math.PI / 2 + pct * 2 * Math.PI);
            if (pct <= 0.2 && !carregando)
                cr.setSourceRGB(1, 0.23, 0.19);
            else
                cr.setSourceRGB(0.2, 0.78, 0.35);
            cr.stroke();
        }
        cr.$dispose();
    }

    destroy() {
        for (const d of this._aparelhos)
            d.disconnectObject(this);
        this._cliente.disconnectObject(this);
        this.actor.destroy();
    }
}

const CLASSES = {relogio: Relogio, calendario: Calendario, clima: Clima, baterias: Baterias};

export default class WidgetsMesa extends Extension {
    enable() {
        this._settings = this.getSettings();
        this._interface = new Gio.Settings({schema_id: 'org.gnome.desktop.interface'});
        this._coluna = new St.BoxLayout({
            orientation: Clutter.Orientation.VERTICAL,
            style: `spacing: ${ESPACO}px;`,
        });
        Main.layoutManager._backgroundGroup.add_child(this._coluna);
        this._widgets = {};
        this._settings.connectObject('changed', () => this._montar(), this);
        this._interface.connectObject('changed::color-scheme', () => this._montar(), this);
        Main.layoutManager.connectObject('monitors-changed', () => this._posicionar(), this);
        this._largura = this._coluna.connect('notify::width', () => this._posicionar());
        this._montar();
    }

    disable() {
        this._settings.disconnectObject(this);
        this._interface.disconnectObject(this);
        Main.layoutManager.disconnectObject(this);
        for (const w of Object.values(this._widgets))
            w.destroy();
        this._widgets = null;
        this._coluna.disconnect(this._largura);
        this._coluna.destroy();
        this._coluna = null;
        this._settings = this._interface = null;
    }

    _escuro() {
        return this._interface.get_string('color-scheme') === 'prefer-dark';
    }

    _montar() {
        for (const w of Object.values(this._widgets))
            w.destroy();
        this._widgets = {};
        const escuro = () => this._escuro();
        for (const nome of WIDGETS) {
            if (!this._settings.get_boolean(nome))
                continue;
            const w = new CLASSES[nome](escuro);
            if (this._escuro())
                w.actor.add_style_class_name('escuro');
            this._coluna.add_child(w.actor);
            this._widgets[nome] = w;
        }
        this._posicionar();
    }

    _posicionar() {
        const monitor = Main.layoutManager.primaryMonitor;
        if (!monitor || !this._coluna || !this._settings)
            return;
        const largura = this._coluna.width;
        const x = this._settings.get_string('lado') === 'direita'
            ? monitor.x + monitor.width - largura - MARGEM : monitor.x + MARGEM;
        this._coluna.set_position(x, monitor.y + Main.panel.height + MARGEM);
    }
}
