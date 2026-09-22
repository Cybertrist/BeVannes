#!/bin/bash
# La bascule de langue, partagée par tous les scripts de rendu.
#
# LANGUE=fr (par défaut) rend le README français dans png/, stack/, liens/
# et notes/. LANGUE=en rend l'anglais dans les mêmes dossiers suffixés -en.
# installer.sh repose ensuite les uns dans docs/, les autres dans docs/en/.
#
# t <français> <anglais> choisit la chaîne. Chaque texte du README vit donc
# à un seul endroit, ses deux versions côte à côte : en corriger une sans
# voir l'autre est impossible.
LG="${LANGUE:-fr}"
SUF=""; [ "$LG" = en ] && SUF="-en"
t () { if [ "$LG" = en ]; then printf '%s' "$2"; else printf '%s' "$1"; fi; }
