---
layout: post
title: "De l'auto-hébergement - Partie 1 : Un serveur à la maison"
date: 2012-09-27 01:47
comments: false
toc: true
categories: 
- Auto-hébergement
- Serveur
- EFI
- Archlinux
- Systemd
description:
tags: [Société, Homosexualité]
modified:
image:
  path: /images/abstract-7.jpg
  feature: abstract-7.jpg
  visible: false
---

Voici le premier d'un série de posts sur l'installation d'un serveur complet pour distribuer des fichiers dans mon réseau local, ainsi que mettre à disposition quelques outils sur la toile. Nous y aborderons la préparation de la machine en vue d'une utilisation en tant que serveur.

<a name="Read-more"></a>

La configuration du serveur, une fois terminé, comprend:

* Un serveur SSH pour accéder à la machine à distance
* Un serveur Web délivrant ce blog
* Un serveur de son pour envoyer de la musique dans le domicile
* Un serveur de musique en streaming sur le net pour retrouver l'intégralité de ma discothèque partout dans le monde
* Un serveur GIT et son gestionnaire à la Github

## L'auto-hébergement, pourquoi ? ##
Les raisons sont multiples, mais on peut citer quelques particularités ; Le simple défi technique est déjà suffisant en soit, mais d'autres raisons sont facilement envisageables.  
Deezer devenant payant, Grooveshark étant peu fiable au niveau qualité de la musique, pouvoir écouter de partout ses propres disques légalement acquis est un levier de motivation suffisant en lui-même ; La distribution de la musique dans la maison reste un moyen de se faire mousser en soirée.

Enfin, moins dépendre des géants du web tout en combattant à son échelle le <q>Minitel 2.0</q> est une manière de militer pour un internet plus ouvert... Enfin, c'est ce dont on se persuade avant de rejoindre le Parti Pirate.

## Un article de blog, pourquoi ? ##
Ayant un tant soit peu galéré à plusieurs étapes, et ne trouvant pas toujours sur le net les ressources pouvant m'aider pour mon exact problème, je me suis naïvement dit que l'expérience d'un seul pouvait aider la communauté. Et puis, cela justifie la création du blog !

## La Machine et son OS ##
Suite à la mort de l'ancien serveur (qui ne faisait en gros que du streaming et servir des fichiers en local) à base des premières générations d'Atom, j'ai décidé d'opter pour quelque chose de plus robuste, tout en conservant le côté <q>économie d'énergie</q> et silence de ces petites boites qui savent se faire discrètes.

Une recherche (pas forcément plus appronfondie que cela m'a amené à découvrir la plateforme Brazos d'AMD. Du coup, j'ai fini par céder aux sirènes d'une Zotac ZBox AD02 assortie de 8Go de RAM et d'un gros disque dur.

###  Média d'installation ###
Le choix du système d'exploitation s'est fait sur la distribution Archlinux ; Elle n'est pas officiellement destinée aux serveurs, et j'ai plus l'habitude d'utiliser une Debian dans ce cas. Malgré cela, Archlinux propulse la majorité de mes PC depuis quelques temps, et j'apprécie particulièrement son outil de fabrication de paquets qui me permet d'installer proprement virtuellement n'importe quoi en toute simplicité, tout comme son côté <q>rocailleux</q> et simple dans sa mise en oeuvre.  
Je ne pouvais d'ailleurs pas rêver plus rocailleux, l'installeur étant passé à la trappe au profit de scripts dans la dernière version du media d'installation.

#### Préparation ####
Afin de s'incrire dans la modernité, le BIOS ayant été remplacé par un EFI sur la machine, j'ai décidé d'utiliser les capacités nouvelles de ce système, ce qui a compliqué un peu la préparation du matériel.

Téléchargeons l'iso de notre distribution ici : <http://mir.archlinux.fr/iso/latest/>

Le réflexe classique serait de graver l'image / utiliser `dd` sur notre clef USB ; Malheureusement ce la ne prend pas en compte notre volonté d'utiliser EFI sur notre machine.

**Il nous faudra un autre PC sous linux pour préparer cette clef USB**

* Extraire le contenu de l'image dans un répertoire temporaire (ici `/tmp/iso`)

* Extraire contenu de `/tmp/iso/EFI/archiso/efiboot.img` dans un second répertoire temporaire (ici `/tmp/efiboot`)

* Créer s'ils n'existent pas les répertoires `archiso` et `boot` dans `/tmp/iso/EFI/` :

```
mkdir -p /tmp/iso/EFI/{archiso, boot}/
```

* Copier le noyau et l'initrd dans le répertoire qui sera chargé par EFI, le shell EFI, et le script qui permettra au shell de booter le noyau :

```
$ cp /tmp/iso/arch/boot/x86_64/vmlinuz /tmp/iso/EFI/archiso/vmlinuz.efi
$ cp /tmp/iso/arch/boot/x86_64/archiso.img /tmp/iso/EFI/archiso/archiso.img
$ cp /tmp/efiboot/bootx64.efi /tmp/iso/EFI/boot/bootx64.efi
$ cp /tmp/efiboot/startup.nsh /tmp/iso/EFI/boot/startup.nsh
```

* Formater une clef USB au format EFI (FAT/FAT32 bootable)  
Avec GPT fdisk , sur ma clef de 2Go :

```
$ gdisk /dev/sde
```

    d (delete partition) jusqu'à ce qu'il n'y en ai plus
    n (new partition)
    Partition number[Enter] (première partition, la seule)
    First Sector[Enter] (créée au début du disque)
    Last Sector[-100M] (les disques au format GPT doivent avoir quelques octets à la fin pour recopier la table de partition, je prends large)
    GUID[EF00] (On déclare la partition comme une parition EFI - bootable)
    w (write to disk)
 
* On recherche le label du disque prévu par le script, c'est comme cela que celui-ci saura retrouver la clef USB :

```
cat /tmp/iso/EFI/boot/startup.ns | grep archisolabel
```

    > vmlinuz.efi archisobasedir=arch archisolabel=ARCH_201209 initrd=\EFI\archiso\archiso.img

* Formater la partition au format Fat32 en lui donnant le bon label :

```
mkfs.vfat -F32 -n ARCH_201209 /dev/sde1
```

* On copie le contenu de `/tmp/iso` sur la clef USB

La préparation de la clef USB est terminée et on ne peut qu'espérer que cela se simplifie avec le temps.

#### Boot ####
Bien évidemment cela se passe mal, le script ne veut pas se lancer, et je n'ai que le shell EFI qui se lance avec son prompt.  
La clef USB ayant servi à booter, on se dit que c'est le premier disque (croisons les doigts – sinon on essaye de 0 à X ^^ ) :

```
fs0:
cd EFI
cd boot
startup.ns
```

… ouf.

### Installation de l'OS ###

On commence par régler le clavier pour prendre en compte la disposition AZERTY :

```
# loadkeys fr-pc
```

#### Partionnement du disque et formatage ####

On est reparti pour utiliser `gdisk`

<table>
	<tr>
		<th align="center">Last Sector (Taille)</th>
		<th align="center">Type de partition</th>
		<th align="center">Formatage</th>
		<th align="center">Point de montage</th>
	</tr>
	<tr>
		<td align="center">+200M</td>
		<td align="center">Linux partition
			(8300)
		</td>
		<td align="center">ext2</td>
		<td align="center">/boot</td>
	</tr>
	<tr>
		<td align="center">+512M</td>
		<td align="center">EFI partition
			(EF00)
		</td>
		<td align="center">FAT32</td>
		<td align="center">/boot/efi</td>
	</tr>
	<tr>
		<td align="center">+4G</td>
		<td align="center">Linux Swap
			(8200)
		</td>
		<td></td>
		<td></td>
	</tr>
	<tr>
		<td align="center">+80G</td>
		<td align="center">Linux partition</td>
		<td align="center">ext4</td>
		<td align="center">/</td>
	</tr>
	<tr>
		<td align="center">+80G</td>
		<td align="center">Linux partition</td>
		<td align="center">ext4</td>
		<td align="center">/var</td>
	</tr>
	<tr>
		<td align="center">+80G</td>
		<td align="center">Linux partition</td>
		<td align="center">ext4</td>
		<td align="center">/srv</td>
	</tr>
	<tr>
		<td align="center">-50M</td>
		<td align="center">Linux partition</td>
		<td align="center">ext4</td>
		<td align="center">/home</td>
	</tr>
</table>

Les nouvelles bonnes pratiques mettent tout ce qui est serveur web sur /srv (cela ne nous rajeunit pas, je pensais tout mettre dans /var/www/ moi !)  
On a de la place, on en profite, et on laisse de l'espace à la fin du disque pour la redondance de la table de partition.

Ensuite, on formate tout cela, et on initialise le SWAP :

```
# mkfs.ext2 /dev/sda1
# mkfs.vfat -F32 /dev/sda2
# mkswap /dev/sda3
# mkfs.ext4 /dev/sda4
# mkfs.ext4 /dev/sda5
# mkfs.ext4 /dev/sda6
# mkfs.ext4 /dev/sda7
```

On monte les partitions :

```
# swapon /dev/sda3
# mount /dev/sda4 /mnt
# mkdir /mnt/{boot,var,srv,home}
# mkdir /mnt/boot/efi
# mount /dev/sda1 /mnt/boot
# mount /dev/sda2 /mnt/boot/efi
# mount /dev/sda5 /mnt/var
# mount /dev/sda6 /mnt/srv
# mount /dev/sda7 /mnt/home
```

#### Installation base du système ####
Je n'aime pas nano, et j'ai beaucoup de mal avec vi de base, il me faut donc Vim le plus rapidement possible avec le reste des paquets de base !

```
# pacstrap /mnt base base-devel vim
```

Le chargeur de démarrage :

```
# pacstrap /mnt grub-efi-x86_64
```

On génère maintenant la liste des partitions à partir de l'UUID des disques :

```
# genfstab -p /mnt >> /mnt/etc/fstab -U
```

Enfin, on `chroot` dans le système nouvellement installé

```
# arch-chroot /mnt
# export LANG=fr_FR.UTF-8
```

#### Fichiers de configuration ####

##### Nom de la machine (En ce moment, l'univers de Harry Potter) #####

{% codeblock /etc/hostname %}
Dumbledore
{% endcodeblock %}

{% codeblock /etc/hosts %}
#
# /etc/hosts: static lookup table for host names
#

#<ip-address>   <hostname.domain.org>   <hostname>
127.0.0.1       localhost.localdomain   localhost       Dumbledore      dumbledore.baradoz.org
::1             localhost.localdomain   localhost       Dumbledore      dumbledore.baradoz.org
{% endcodeblock %}

##### Langues et encodages #####

{% codeblock lang:cfg /etc/locale\.conf %}
# Spécifier fr par défaut, Unicode
LANG="fr_FR.UTF-8"
LC_ALL="fr_FR.UTF-8"

# Préférer l'anglais à la langue par défaut si la traduction fr n'existe pas
LANGUAGE="fr_FR:en_US"
{% endcodeblock %}

{% codeblock lang:cfg /etc/vconsole\.conf %}
#Disposition du clavier
KEYMAP=fr-pc
{% endcodeblock %}

Dans le fichier `/etc/locale.gen`, décommenter :

    fr_FR.UTF-8 UTF-8
    fr_FR ISO-8859-1

##### Fuseau horaire #####

{% codeblock /etc/timezone %}
Europe/Paris
{% endcodeblock %}

##### Génération des locales #####

Une fois les fichiers de configuration pour les locales préparés, on génère les locales FR et les horaires CEST :

```
# ln -s /usr/share/zoneinfo/Europe/Paris /etc/localtime
# locale-gen
```

#### Préparation du redémarrage ####
##### Construction du ramdisk de démarrage #####

```
# mkinitcpio -p linux
```

##### Configuration de GRUB #####

```
# grub-mkconfig -o /boot/grub/grub.cfg
```

##### Root et redémarrage #####

On choisi le mot de passe root, on quitte l'environnement chrooté, on démonte tout ce qu'on a monté, et on redémarre le système:

```
# passwd
# exit
# umount /mnt/boot/efi /mnt/boot /mnt/var /mnt/srv /mnt/home /mnt
# reboot
```

### Systemd ###

Plutot qu'un environnement mixte, je prends de l'avance, et j'ai pris le parti d'entièrement passer à Systemd comme système d'init.

#### Préparatifs ####

* On enleve toute référence à l'option `codepage` dans le fichier `/etc/fstab/`, qui a empêché le redémarrage avec Systemd à ma première tentative.

* On charge temporairement Systemd comme système d'init au prochain démarrage dans la configuration de GRUB

```
# vim /boot/grub/grub.cfg
```

On remplace :

    linux   /vmlinuz-linux root=UUID=adf0fa25-a024-4902-a76e-2cb5b0664a09 ro quiet

par :

    linux   /vmlinuz-linux root=UUID=adf0fa25-a024-4902-a76e-2cb5b0664a09 ro quiet init=/bin/systemd

Puis on redémarre (en croisant les doigts)

#### Configuration de Systemd ####

Remplacer tous les démons de rc.conf par leur équivalent systemd

La journalisation est déjà active par défaut, syslog ne nous servira pas.

Le réseau et cron :

```
# systemctl enable dhcpcd@eth0.service
# systemctl enable cronie.service
```

On redémarre pour tester, et si tout fonctionne, on désactive l'ancien init !

#### Full Systemd ####

On enleve le `init=/bin/systemd` du fichier de configuration GRUB

On remplace les initscripts par quelques alias bien placés :

```
# pacman -R sysvinit initscripts
# pacman -S systemd-sysvcompat
```

On redémarre, c'est terminé... Nous avons un serveur fonctionnel !

... comment cela, il ne sert rien ? Oui, mais bon, c'est marqué « Partie 1 » en haut, hein :D
