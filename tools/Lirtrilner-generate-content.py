"""Deterministic authored puzzle families. No runtime procedural content."""
import json, random
from pathlib import Path
ROOT = Path(__file__).resolve().parents[1]

def build(n, daily=False):
    rng = random.Random(n + (900 if daily else 0))
    cells = [{'terrain':'normal'} for _ in range(25)]
    cells[24]['terrain'] = 'delivery'
    actions, supplies, orders = [], [], []
    serial = 0
    def put(i, kind, level):
        nonlocal serial
        serial += 1
        cells[i]['part'] = dict(id=serial, kind=kind, level=level)
    def slide(d, i): actions.append(dict(direction=d,index=i))
    def deliver(kind, level):
        actions.append(dict(index=0))
        found = next((o for o in orders if o['kind']==kind and o['level']==level), None)
        if found: found['required'] += 1
        else: orders.append(dict(kind=kind,level=level,required=1,delivered=0))
    if n == 1 and not daily:
        put(20,'gear',1); put(22,'gear',1)
        slide('right',4); deliver('gear',2)
    elif n == 2 and not daily:
        put(0,'gear',1); put(10,'gear',1)
        put(2,'battery',1)
        slide('down',0); slide('right',4); deliver('gear',2)
    elif n == 3 and not daily:
        cells[12]['terrain']='obstacle'
        cells[22]['terrain']='obstacle'
        put(3,'gear',1); put(13,'gear',1)
        slide('down',3); slide('right',4); deliver('gear',2)
    else:
        difficulty = 1 if n < 13 and not daily else (2 if n < 25 and not daily else 3)
        count = 2 if difficulty < 3 else 3
        rows = rng.sample([0,1,2,3], count)
        kinds = ['gear','battery','gear'] if n % 2 else ['battery','gear','battery']
        for k, row in enumerate(rows):
            rank = 1 if difficulty == 1 else rng.randint(1, min(3,difficulty))
            kind = kinds[k]
            columns = rng.sample([0,1,2] if n % 3 == 0 and k > 0 else [0,1,2,3],2)
            # Alternate parallel horizontal assemblies and vertical assemblies.
            if k == 0 and n % 3 == 0:
                col = 3
                put(row*5+col,kind,rank)
                put(4*5+col,kind,rank)
                slide('down',col); slide('right',4)
            else:
                put(row*5+columns[0],kind,rank)
                put(row*5+columns[1],kind,rank)
                slide('right',row); slide('down',4)
            deliver(kind,rank+1)
        # Supply is essential for a final order in every fourth puzzle.
        if n % 4 == 0:
            free_row = next(r for r in [0,1,2,3] if r not in rows)
            supplies = [dict(index=free_row*5,kind='battery',level=1),dict(index=free_row*5+2,kind='battery',level=1)]
            slide('right',free_row); slide('down',4); deliver('battery',2)
        protected = {i for i,c in enumerate(cells) if 'part' in c}
        protected |= {r*5+c for r in rows for c in range(5)} | set(range(20,25)) | {4,9,14,19}
        if n%3 == 0:
            protected |= {r*5+3 for r in range(5)}
        if supplies: protected |= {free_row*5+c for c in range(5)}
        candidates = [i for i in range(20) if i not in protected]
        for i in rng.sample(candidates,min(len(candidates),difficulty+1)):
            cells[i]['terrain']='obstacle'
    # Rotations and reflections change both tracks and delivery locations.
    turns = (n + (3 if daily else 0)) % 4 if n > 3 or daily else 0
    mirror = n%2 == 0 and (n>3 or daily)
    def point(i):
        r,c=divmod(i,5)
        for _ in range(turns): r,c=c,4-r
        if mirror: c=4-c
        return r*5+c
    transformed=[None]*25
    for i,c in enumerate(cells): transformed[point(i)]=c
    for s in supplies: s['index']=point(s['index'])
    for a in actions:
        if 'direction' not in a: continue
        d=a['direction']; idx=a['index']
        p = idx*5+2 if d in ('left','right') else 10+idx
        dr,dc={'left':(0,-1),'right':(0,1),'up':(-1,0),'down':(1,0)}[d]
        q=p+dr*5+dc
        rr,cc=divmod(point(p),5); r2,c2=divmod(point(q),5)
        nd = 'down' if r2>rr else 'up' if r2<rr else 'right' if c2>cc else 'left'
        a.update(direction=nd,index=rr if nd in ('left','right') else cc)
    return dict(schemaVersion=1,contentVersion=1,id=f"{'daily' if daily else 'story'}-{n:02}",number=n,daily=daily,toy=(n-1)//3 if not daily else (n-1)%12,stage=(n-1)%3+1,board=transformed,orders=orders,moveLimit=sum('direction' in a for a in actions)+(2 if n<4 else 4),supplies=supplies,reference=actions)

levels=[build(n) for n in range(1,37)]+[build(n,True) for n in range(1,31)]
(ROOT/'Lirtrilner/Lirtrilner-levels.json').write_text(json.dumps(levels,indent=2)+'\n')
print('Generated 36 story + 30 daily puzzles. Verify with swift test.')
