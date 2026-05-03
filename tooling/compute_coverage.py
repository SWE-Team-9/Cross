LF=0
LH=0
with open('coverage/lcov.info','r',encoding='utf-8') as f:
    for l in f:
        l=l.strip()
        if l.startswith('LF:'):
            try:
                LF += int(l.split(':',1)[1])
            except:
                pass
        elif l.startswith('LH:'):
            try:
                LH += int(l.split(':',1)[1])
            except:
                pass
print(f'LF:{LF} LH:{LH}')
if LF>0:
    pct = round(LH*100.0/LF,2)
    print(f'coverage: {pct}%')
else:
    print('coverage: 0%')
