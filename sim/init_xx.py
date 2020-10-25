
with open('init_xx.txt', 'w') as f:
    for ii in range(0, 64):
        f.write('.INIT_%02X(BRAM_INIT_VAL[%d]),\n' % (ii, ii))
f.close()