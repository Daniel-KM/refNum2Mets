refNum vers Mets
================

[refNum2Mets] est un outil pour convertir des fichiers xml du format [refNum]
vers le format [Mets], deux formats utilisés pour gérer des documents numérisés
et pour construire des bibliothèques numériques.

Le format [refNum] est un format défini par la [Bibliothèque nationale de France],
ou [BnF], pour gérer les numérisations de documents (livres, journaux, objets,
audio). Il est officiellement abandonné depuis décembre 2014 au profit du Mets
(mais officieusement encore utilisé et toujours mis à jour) .

Cet outil permet donc de mettre à jour ses fichiers de métadonnées en conservant
l’ensemble des informations du premier format et éventuellement en en ajoutant
de nouvelles.

Cette feuille a été vérifiée avec les documents numérisés de la [bibliothèque]
de l’[École des Mines] de Paris et de l’[École des Ponts] (monographies,
manuscrits, périodiques, lots de photos), mis en ligne sur leurs sites
respectifs [Bibliothèque patrimoniale des Mines] et [Collections patrimoniales des Ponts]
via la plateforme libre [Omeka]. Elle gère aussi quelques variantes du refNum
(genre inconnu, dates multiples, etc.). À l’inverse, certaines spécificités du
refNum ne sont pas prises en compte, notamment pour les objets "texte" et
"audio" et pour les fichiers associés.

Le format est conçu sur la base du profil METS SIP de la BnF (noms des
identifiants...) et sur les différents documents disponibles sur la page
consacrée aux [bibliothèques numériques] sur le site de la [BnF], mais il est
possible de s’en écarter pour simplifier ou enrichir le résultat.


Utilisation
-----------

La feuille utilise le langage [xslt] dans sa version 2, conçu par le
[World Wide Web Consortium], qui doit être installé préalablement, par exemple
la version libre de [Saxonica]. Elle est utilisable en ligne de commandes ou via
un éditeur de texte tel que l’éditeur libre multiplateforme [jEdit], avec les
[plugins xml et xslt] correspondants.

Consulter les remarques figurant dans la feuille xslt et dans le fichier de
configuration.

L’ensemble des paramètres doivent être indiqués dans le fichier de configuration
associé "refNum2Mets_config.xml".

La feuille peut utiliser les informations sur les documents et sur les fichiers
qui se trouvent dans les fichiers associés pour les identifiants arks, les
hashs, les tailles de fichiers et les métadonnées complémentaires. Pour ces
derniers, le fichier correspond à "content.xml" qui se trouve dans un fichier
Open Document Spreadsheet. Pour l’obtenir, créer un tableau avec LibreOffice ou
tout autre tableur respectueux des standards, l’enregistrer au format "ods", et
dézipper ce fichier. Un exemple est fourni. Le script utilise directement l’un
ou l’autre format.

Avec certains parseurs, les fichiers additionnels doivent être présents, même
vides, pour éviter les erreurs.


Exemple
-------

Pour essayer l’exemple, lancer ces deux commandes dans un terminal :

```
cd metadata
../refNum2Mets.sh
```


Notes sur la conversion
-----------------------

La conversion des métadonnées ne pose pas de problème particulier, sauf pour
certaines informations sur les images. Elles sont explicitées dans cette table
de conversion des informations sur les objets numérisés avec refNum, Mets et
Dublin Core Terms pour Omeka.

                         | Exemple         | refNum [Mines]                                                                  | Mets                                            | Dublin Core Terms [dans Omeka]
-------------------------|-----------------|---------------------------------------------------------------------------------|-------------------------------------------------|---------------------------------------------------------
Total des vues           | 20              | production/nombreVueObjets                                                      | count(structMap//div[not(div)])                 | count(HasPart) (niveau document) [interne]
Total des images         | 24              | production/nombreImages                                                         | count(fileSec/fileGrp[@USE="master"]/file)      | count(IsPartOf) (niveau fichier) [interne]
Ordre d’une image        | 13              | structure/vueObjet/@ordre                                                       | structMap//div/@ORDER                           | ordre de HasPart (niveau document) [interne]
Type d’image générique   | Page            | structure/vueObjet/@typePage (par déduction)                                    | structMap//div/@TYPE (et dans dmdSec)           | Type
Numéro de page           | iii             | structure/vueObjet/@numeroPage ("3") + structure/vueObjet/@typePagination ("R") | structMap//div/@ORDERLABEL (et dans dmdSec)     | Title
Type précis, s’il existe | Index           | structure/vueObjet/@typePage ("I")                                              | structMap//div/@LABEL (partiel, et dans dmdSec) | Description (partie du nom de page après le premier ":")
Nom de page              | Page iii: Index | structure/vueObjet/@typePage + numéro de page + type précis                     | structMap//div/@LABEL (et dans dmdSec)          | Description
Sens de lecture          | 90°             | [structure/vueObjet/@orientation ("P")]                                         | dmdSec/mdWrap/xmlData/dc:dc/dc:format           | Format ("Orientation: 90°)
Position de la page      | Droite          | [structure/vueObjet/@position]                                                  | dmdSec/mdWrap/xmlData/dc:dc/dc:format           | Format ("Position: Right")
Première page à afficher | 2               | structure/vueObjet/@typePage ("E")                                              | ?                                               | ? [ou Format ("First to display") au niveau document]

Notes :
- En Mets, les métadonnées descriptives reprennent les attributs de la division
correspondante dans le plan de la structure (type => type, order label => title,
label => description).
- En Mets, les métadonnées descriptives des documents et des fichiers sont
formatées en Dublin Core selon le profil.
- Sens de lecture de la page pour le Mets: "amdSec/techMD/mdWrap/xmlData/niso:Orientation"
("1" = normal, etc.) ne peut pas être utilisé, car, selon la définition, ce
champ doit être utilisé seulement pour l’image stockée, pas pour l’orientation
de la source par rapport à l’appareil (par exemple l’appareil photo) au moment
de la prise, ni pour l’orientation correcte lorsque l’image est affichée sur un
appareil de diffusion.
- La position of the page est nécessaire seulement lorsqu’elle n’est pas
standard (parité paire/impaire), notamment les livres anciens et les manuscrits,
ou pour les papiers insérés ou pour certaines pages manquantes ou non
numérisées.
- En Dublin Core, le document fait l’objet d’une notice et chaque fichier
attaché est lié par la relation Has Part / Is Part Of. Par ailleurs, Omeka gère
ce lien en interne.


Avertissement
-------------

À utiliser à vos risques et périls.

Il est toujours recommandé de sauvegarder ses fichiers et ses métadonnées
régulièrement afin de pouvoir les retrouver en cas de besoin.


Problèmes
---------

Signaler les remarques en ligne sur la page des [questions] de GitHub.


License
-------

Cet outil est publié sous licence [CeCILL v2.1], compatible avec la licence
[GNU/GPL] et approuvé par la [FSF] et l’[OSI].

L’accessibilité au code source et les droits de copie, de modification et de
redistribution qui en découlent ont pour contrepartie de n’offrir aux
utilisateurs qu’une garantie limitée et de ne faire peser sur l’auteur du
logiciel, le titulaire des droits patrimoniaux et les concédants successifs
qu’une responsabilité restreinte.

A cet égard l’attention de l’utilisateur est attirée sur les risques associés au
chargement, à l’utilisation, à la modification et/ou au développement et à la
reproduction du logiciel par l’utilisateur étant donné sa spécificité de
logiciel libre, qui peut le rendre complexe à manipuler et qui le réserve donc à
des développeurs ou des professionnels avertis possédant des connaissances
informatiques approfondies. Les utilisateurs sont donc invités à charger et
tester l’adéquation du logiciel à leurs besoins dans des conditions permettant
d’assurer la sécurité de leurs systèmes et/ou de leurs données et, plus
généralement, à l’utiliser et l’exploiter dans les mêmes conditions de sécurité.
Ce contrat peut être reproduit et diffusé librement, sous réserve de le
conserver en l’état, sans ajout ni suppression de clauses.


Contact
-------

Mainteneur actuel :

* Daniel Berthereau (voir [Daniel-KM] sur GitHub)


Copyright
---------

* Copyright Daniel Berthereau, 2015 pour l’École des Mines de Paris ([Mines ParisTech])


[refNum2Mets]: https://github.com/Daniel-KM/refNum2Mets
[Bibliothèque nationale de France]: http://www.bnf.fr
[refNum]: http://bibnum.bnf.fr/refNum
[Mets]: https://www.loc.gov/standards/mets
[BnF]: http://www.bnf.fr
[bibliothèque]: http://bib.mines-paristech.fr
[École des Mines]: https://www.mines-paristech.fr
[École des Ponts]: http://www.enpc.fr
[Bibliothèque patrimoniale des Mines]: https://patrimoine.mines-paristech.fr
[Collections patrimoniales des Ponts]: http://patrimoine.enpc.fr
[Omeka]: https://omeka.org
[bibliothèques numériques]: http://bibnum.bnf.fr
[xslt]: https://www.w3.org/TR/xslt20
[World Wide Web Consortium]: https://www.w3.org
[Saxonica]: http://www.saxonica.com/download/opensource.xml
[jEdit]: http://www.jedit.org
[plugins xml et xslt]: http://plugins.jedit.org/list.php?category=4
[questions]: https://github.com/Daniel-KM/refNum2Mets/issues
[CeCILL v2.1]: https://www.cecill.info/licences/Licence_CeCILL_V2.1-fr.html
[GNU/GPL]: https://www.gnu.org/licenses/gpl-3.0.html
[FSF]: https://www.fsf.org
[OSI]: http://opensource.org
[bibliothèque]: http://bib.mines-paristech.fr
[Mines ParisTech]: https://www.mines-paristech.fr
[Daniel-KM]: https://github.com/Daniel-KM "Daniel Berthereau"
