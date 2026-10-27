<div align="center">

# OhMyMac

**macOS-вигляд для GNOME 51 — на будь-якому дистрибутиві.**

GTK 3 · GTK 4 / libadwaita · GNOME Shell · GDM · Flatpak

[![CI](https://github.com/cmpdchtr/OhMyMac/actions/workflows/ci.yml/badge.svg)](https://github.com/cmpdchtr/OhMyMac/actions/workflows/ci.yml)
![GNOME 47–51](https://img.shields.io/badge/GNOME-47–51-4a86cf?logo=gnome&logoColor=white)
![License: GPL-3.0](https://img.shields.io/badge/license-GPL--3.0-blue)

[English summary](#english) · [Встановлення](#встановлення) · [Що змінюється](#що-змінюється) · [Видалення](#видалення)

</div>

---

OhMyMac — це тема та інсталятор, що перетворюють GNOME на щось дуже схоже на macOS
Tahoe: «світлофор» у заголовках вікон, кольори й заокруглення macOS, меню-бар,
Control Center і Dock у GNOME Shell, шрифт Inter (або SF Pro, якщо він у вас є),
іконки MacTahoe та курсори macOS.

Проєкт натхненний модпаком [macW1Y](https://github.com/w1nyear/macW1Y-GTK-Theme), але
переписаний з нуля з іншими принципами:

| macW1Y | OhMyMac |
| --- | --- |
| Лише Ubuntu + `apt` | 9 сімейств дистрибутивів, immutable-системи, NixOS |
| ~150 МБ вшитих тем, іконок, шрифтів і чужих розширень | Компактні SCSS-джерела; іконки, курсори й розширення беруться з upstream |
| Повна копія CSS GNOME Shell конкретної версії | Тонкий шар поверх стокового CSS вашої версії Shell — не ламається з оновленнями |
| Змінює GRUB, Plymouth, sysctl, udev, sudoers… | Лише оформлення; системні файли — тільки за явним `--gdm` |
| Деінсталятор «вгадує», що видаляти | Маніфест встановлених файлів + бекап кожного змінного параметра |

## Можливості

- **GTK 4 / libadwaita** — палітра macOS через публічні CSS-змінні libadwaita,
  світла й темна схеми в одному файлі (`prefers-color-scheme`), акцентні кольори
  macOS для всіх 9 акцентів GNOME.
- **GTK 3** — побудовано поверх Adwaita, вбудованої в libgtk-3: усе, що ми не
  перемальовуємо, лишається коректним.
- **Вікна** — кнопки-«світлофор» ліворуч із гліфами при наведенні, заокруглення
  14 px, тонкі macOS-скролбари, перемикачі, чекбокси, повзунки, меню з
  виділенням акцентним кольором.
- **GNOME Shell** — напівпрозорий меню-бар, Quick Settings у стилі Control Center,
  календар і сповіщення як у Notification Center, «скляний» Dock (і для Dash to
  Dock), OSD, перемикачі вікон, діалоги, екран блокування.
- **Автоматичний світлий/темний режим** — `ohmymac-sync` перемикає GTK 3,
  тему Shell та іконки разом із системним перемикачем.
- **Розширення** з extensions.gnome.org **саме для вашої версії GNOME**: несумісні
  пропускаються, а не ламають сесію.
- **Flatpak** — застосунки в пісочниці отримують теми, іконки й стилі libadwaita.
- **Екран входу (GDM)** — опційно, з резервною копією й відновленням.
- **Чесне видалення** — `uninstall.sh` повертає ваші попередні налаштування та файли.

## Підтримувані системи

| Сімейство | Дистрибутиви (приклади) | Пакетний менеджер |
| --- | --- | --- |
| Debian | Debian, Ubuntu, Linux Mint, Pop!\_OS, Zorin, elementary | `apt` |
| Fedora | Fedora Workstation, Nobara, RHEL/Alma/Rocky | `dnf` |
| Arch | Arch, EndeavourOS, Manjaro, CachyOS, Garuda | `pacman` |
| openSUSE | Tumbleweed, Leap, Slowroll | `zypper` |
| Void | Void Linux (glibc/musl) | `xbps` |
| Alpine | Alpine, postmarketOS | `apk` |
| Gentoo | Gentoo, Funtoo | `emerge` |
| Solus | Solus | `eopkg` |
| Immutable | Silverblue, Bluefin, Aurora, Aeon, Vanilla OS | — (усе встановлюється в `$HOME`) |
| NixOS | NixOS | — (підказує пакети для `configuration.nix`) |

**GNOME:** цільова версія — **51**, підтримуються **47–51**. На старіших версіях GTK-теми
працюють, а Shell-тема може виглядати неідеально. GNOME 50+ працює лише у Wayland —
OhMyMac розрахований саме на нього.

## Встановлення

```bash
git clone https://github.com/cmpdchtr/OhMyMac.git
cd OhMyMac
./install.sh
```

Інсталятор покаже, що знайшов (дистрибутив, версію GNOME, сесію), і запитає, які
компоненти ставити. Права адміністратора потрібні лише для пакетів залежностей і
(за бажанням) для екрана входу — `sudo`, `doas` чи `run0` викликаються самі.
**Не запускайте `install.sh` через `sudo`.**

Після встановлення **вийдіть із сесії й увійдіть знову**: у Wayland Shell не можна
перезапустити, тому нові розширення підхоплюються лише при вході.

### Найчастіші варіанти

```bash
./install.sh --all -y                      # усе, без запитань (включно з GDM)
./install.sh --themes-only                 # тільки теми, без розширень та іконок
./install.sh --variant dark --accent purple
./install.sh --extensions minimal          # лише User Themes
./install.sh --dry-run                     # показати, що буде зроблено
sudo ./install.sh --system --themes-only   # теми для всіх користувачів
```

### Усі параметри

| Параметр | Опис |
| --- | --- |
| `--all` | Усе, включно з повним набором розширень і екраном входу |
| `--themes-only` | Лише GTK 3/GTK 4/libadwaita/Shell |
| `--no-icons`, `--no-cursors`, `--no-fonts`, `--no-wallpaper` | Пропустити компонент |
| `--no-extensions` / `--extensions minimal\|recommended\|full` | Розширення GNOME Shell |
| `--no-settings` | Не змінювати жодних налаштувань GNOME |
| `--no-flatpak` | Без інтеграції з Flatpak |
| `--gdm` | Оформити екран входу (потрібен root) |
| `--variant auto\|light\|dark` | Світла/темна схема (`auto` — як у системі) |
| `--accent blue\|teal\|green\|yellow\|orange\|red\|pink\|purple\|slate` | Акцентний колір |
| `--system` | Встановити теми й іконки для всіх користувачів |
| `--dest DIR` | Підготувати файли в `DIR` (для пакувальників) |
| `--no-deps` | Ніколи не викликати пакетний менеджер |
| `--allow-incompatible` | Ставити розширення, не позначені для вашої версії GNOME |
| `--update-extensions` | Перезавантажити вже встановлені розширення |
| `-y`, `-n`, `-v` | Без запитань / пробний запуск / докладний вивід |

## Що змінюється

**Файли** (усі записуються в маніфест `~/.local/state/ohmymac/manifest`):

| Шлях | Що це |
| --- | --- |
| `~/.local/share/themes/OhMyMac-{Light,Dark}` | GTK 3, GTK 4 та Shell-теми |
| `~/.themes/OhMyMac-*` | Символьні посилання для Flatpak |
| `~/.config/gtk-4.0/gtk.css` | Стилі libadwaita (ваш попередній файл зберігається) |
| `~/.local/share/gnome-shell/extensions/…` | Розширення з extensions.gnome.org |
| `~/.local/share/icons/{MacTahoe*,macOS*}` | Іконки й курсори з upstream |
| `~/.local/share/fonts/Inter` | Inter, якщо пакета немає в дистрибутиві |
| `~/.local/share/backgrounds/ohmymac` | Шпалери (оригінальні, світла/темна пара) |
| `~/.local/bin/ohmymac-sync`, `~/.config/autostart/ohmymac-sync.desktop` | Синхронізація світлої/темної теми |

**Налаштування GNOME** описані у [`data/settings/`](data/settings) — простих
текстових файлах `схема ключ значення`. Перед першою зміною кожного ключа його
значення зберігається в `~/.local/state/ohmymac/gsettings.backup`. Ключі, яких немає
у вашій версії GNOME, просто пропускаються.

**Розширення** — профілі в [`data/extensions/`](data/extensions):

| Профіль | Розширення |
| --- | --- |
| `minimal` | User Themes |
| `recommended` *(типово)* | + Dash to Dock, Blur my Shell, AppIndicator, Logo Menu, Magic Lamp |
| `full` | + Kiwi, Just Perfection, Rounded Window Corners, Top Bar Organizer |

Конфліктні розширення (наприклад, Ubuntu Dock при встановленні Dash to Dock)
вимикаються автоматично.

## Видалення

```bash
./uninstall.sh            # усе, що встановив OhMyMac, + відновлення налаштувань
./uninstall.sh --gdm      # також повернути стоковий екран входу
./uninstall.sh --keep-settings
```

## Як це працює

```
src/sass/            SCSS-джерела: палітра, токени, GTK 3, GTK 4, Shell
  _palette.scss      системні кольори macOS (світлі й темні)
  _colors.scss       семантичні кольори для поточного варіанта
  _tokens.scss       радіуси, розміри, анімації
  gtk3/ gtk4/ gnome-shell/
lib/                 модулі інсталятора (bash)
  distro.sh          визначення дистрибутива, GNOME, immutable-систем
  packages.sh        відображення залежностей на пакети 9 менеджерів
  build.sh           компіляція SCSS (sassc або dart-sass)
  themes.sh          теми, libadwaita, Flatpak, шрифти, іконки, курсори
  extensions.sh      extensions.gnome.org для поточної версії Shell
  settings.sh        GSettings із бекапом і відновленням
  gdm.sh             перебудова GResource екрана входу
data/                профілі розширень і пресети налаштувань
bin/ohmymac-sync     синхронізація світлої/темної теми
packaging/           PKGBUILD (Arch) та .spec (Fedora)
tests/               юніт-тести, збірка, round-trip встановлення
```

Ключова ідея — **не копіювати стокові стилі, а нашаровуватись на них**:

- GTK 3-тема імпортує `resource:///org/gtk/libgtk/theme/Adwaita/gtk-contained.css`;
- libadwaita стилізується через її публічні CSS-змінні;
- Shell-тема під час встановлення отримує `@import` саме того стокового файлу, що є у
  вашій системі (`gnome-shell-{light,dark}.css` у GNOME 47+, `gnome-shell.css` раніше).

Тож оновлення GNOME не ламає тему: усе, що OhMyMac не чіпає, лишається upstream.

## Розробка

```bash
make build     # зібрати CSS у build/
make lint      # shellcheck + збірка
make test      # повний набір тестів (ізольований $HOME, нічого не змінює)
make dist      # tar.xz з уже зібраним CSS (встановлюється без Sass)
```

CI перевіряє shellcheck, збірку через sassc і Dart Sass, розбір CSS справжнім GTK 3 і
GTK 4 та запуск інсталятора на Ubuntu, Debian, Fedora, Arch, openSUSE, Alpine і Void.
Див. [CONTRIBUTING.md](CONTRIBUTING.md).

## Шрифти та товарні знаки

OhMyMac не постачає шрифти Apple, логотипи чи шпалери: їх ліцензії забороняють
поширення. Якщо у вас є ліцензійний SF Pro, покладіть його в `~/.local/share/fonts` —
інсталятор використає його замість Inter. macOS — товарний знак Apple Inc.; проєкт
з Apple не пов'язаний.

## Подяки

- [w1nyear/macW1Y](https://github.com/w1nyear/macW1Y-GTK-Theme) — ідея й натхнення
- [vinceliuice](https://github.com/vinceliuice) — іконки MacTahoe
- [ful1e5/apple_cursor](https://github.com/ful1e5/apple_cursor) — курсори macOS
- [rsms/inter](https://github.com/rsms/inter) — шрифт Inter
- Автори Dash to Dock, Blur my Shell, Kiwi та інших розширень

## Ліцензія

[GPL-3.0-or-later](LICENSE). Шпалери — CC BY-SA 4.0.

---

## English

**OhMyMac** gives GNOME 51 (supported: 47–51) a macOS look on any distribution:
traffic-light window controls, macOS colours and geometry for GTK 3 and
libadwaita apps, a translucent menu bar, Control Center–style Quick Settings and a
glass Dock for GNOME Shell, plus MacTahoe icons, macOS cursors and Inter/SF Pro.

```bash
git clone https://github.com/cmpdchtr/OhMyMac.git && cd OhMyMac && ./install.sh
```

- Works with apt, dnf, pacman, zypper, xbps, apk, emerge and eopkg; installs
  per-user on immutable systems (Silverblue, Bluefin, Aeon…) and NixOS.
- Layers on top of the stock Adwaita/Shell stylesheets of *your* system instead
  of shipping a frozen copy, so GNOME updates don't break it.
- Fetches extensions from extensions.gnome.org for your exact Shell version and
  skips incompatible ones.
- Records every file it writes and every setting it changes; `./uninstall.sh`
  restores your previous setup.

Run `./install.sh --help` for all options.
