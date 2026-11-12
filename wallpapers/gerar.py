# Desenha com 300 px de sobra em volta (o desfoque não desbota as bordas); corte depois
# Gera papéis de parede abstratos (ondas suaves) em SVG, claro e escuro
import math, sys
W, H = 3840, 2160
THEMES = {
    "claro": {"bg": ("#e6efff", "#fbe9f3"),
              "waves": [("#7fb2ff", 0.55), ("#9b8cff", 0.45), ("#ff9fc8", 0.40), ("#5f8dff", 0.50), ("#c6a8ff", 0.45)]},
    "escuro": {"bg": ("#0a1030", "#1b0f33"),
               "waves": [("#1f4fd8", 0.55), ("#5a2fc9", 0.50), ("#b7347f", 0.40), ("#2a6bf0", 0.45), ("#7b3fe0", 0.45)]},
}

def wave(i, n):
    base = H * (0.30 + 0.13 * i)
    amp = H * (0.10 - 0.012 * i)
    ph = i * 1.3
    pts = []
    for x in range(-200, W + 241, 40):
        k = x / W
        y = base + amp * math.sin(2 * math.pi * (k * (0.8 + 0.15 * i)) + ph) + amp * 0.4 * math.sin(2 * math.pi * k * 2.1 + ph * 2)
        pts.append(f"{x},{y:.1f}")
    return f"M-200,{H+200} L" + " L".join(pts) + f" L{W+240},{H+200} Z"

for name, t in THEMES.items():
    out = [f'<svg xmlns="http://www.w3.org/2000/svg" width="{W+600}" height="{H+600}" viewBox="-300 -300 {W+600} {H+600}">',
           '<defs><linearGradient id="bg" x1="0" y1="0" x2="1" y2="1">'
           f'<stop offset="0" stop-color="{t["bg"][0]}"/><stop offset="1" stop-color="{t["bg"][1]}"/></linearGradient>',
           '<filter id="blur" x="-10%" y="-10%" width="120%" height="120%"><feGaussianBlur stdDeviation="28"/></filter>']
    for i, (c, o) in enumerate(t["waves"]):
        out.append(f'<linearGradient id="w{i}" x1="0" y1="0" x2="1" y2="0.3">'
                   f'<stop offset="0" stop-color="{c}" stop-opacity="{o}"/>'
                   f'<stop offset="1" stop-color="{c}" stop-opacity="{o*0.35:.2f}"/></linearGradient>')
    out.append(f'</defs><rect x="-300" y="-300" width="{W+600}" height="{H+600}" fill="url(#bg)"/><g filter="url(#blur)">')
    for i in range(len(t["waves"])):
        out.append(f'<path d="{wave(i, len(t["waves"]))}" fill="url(#w{i})"/>')
    out.append('</g></svg>')
    open(f"{sys.argv[1]}/{name}.svg", "w").write("\n".join(out))
