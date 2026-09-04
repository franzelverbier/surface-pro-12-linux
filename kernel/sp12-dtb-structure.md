# Comparaison structurelle des DTB — 2026-09-04

Produit par comparaison des CHEMINS DE NŒUDS de deux DTB décompilés.
Un diff textuel serait sans valeur : un DTB décompilé renumérote les phandles,
ce qui produit ici 499 hunks dont la quasi-totalité est du bruit.

```
  494 noeuds chez nous, 520 en amont

  === chez NOUS seulement (1) ===
    /reserved-memory/ramoops@a0000000

  === en AMONT seulement (27) ===
    /channel@103
    /channel@144
    /channel@145
    /channel@146
    /channel@147
    /channel@148
    /channel@14a
    /channel@14b
    /channel@18e
    /channel@203
    /channel@3
    /channel@303
    /channel@403
    /channel@503
    /channel@803
    /channel@903
    /ctcu@10001000
    /ctcu@10001000/in-ports
    /ctcu@10001000/in-ports/port@0
    /ctcu@10001000/port@1
    /out-ports/port@0
    /replicator@10046000
    /replicator@10046000/in-ports
    /replicator@10046000/in-ports/port
    /replicator@1004e000
    … et 2 autres
```

Les nœuds propres à l'amont sont tous CoreSight (traçage matériel), et viennent
de `hamoa.dtsi` — l'include du SoC — non du fichier de carte.
