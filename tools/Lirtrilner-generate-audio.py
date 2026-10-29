import math, wave, struct
from pathlib import Path
root=Path(__file__).resolve().parents[1]/'Lirtrilner'
rate=22050
scores={'move':[(330,.08)],'merge':[(440,.08),(660,.14)],'deliver':[(523,.12),(659,.12),(784,.22)],'complete':[(523,.16),(659,.16),(784,.16),(1046,.4)],'fail':[(330,.16),(247,.3)],'music':[(f,.5) for f in [262,330,392,330,294,349,440,349,330,392,494,392,294,349,392,294,262,330,392,523,440,349,294,392]]}
for name,notes in scores.items():
    samples=[]
    for freq,duration in notes:
        for i in range(int(rate*duration)):
            t=i/rate
            env=min(1,t/.015)*max(0,1-t/duration)**2
            value=(math.sin(2*math.pi*freq*t)+.18*math.sin(4*math.pi*freq*t))*env*.22
            samples.append(int(value*32767))
    with wave.open(str(root/f'Lirtrilner-{name}.wav'),'wb') as out:
        out.setnchannels(1);out.setsampwidth(2);out.setframerate(rate)
        out.writeframes(struct.pack('<'+'h'*len(samples),*samples))
