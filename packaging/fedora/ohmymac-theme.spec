Name:           ohmymac-theme
Version:        1.0.0
Release:        1%{?dist}
Summary:        macOS-inspired GTK 3, GTK 4/libadwaita and GNOME Shell theme
License:        GPL-3.0-or-later
URL:            https://github.com/cmpdchtr/OhMyMac
Source0:        %{url}/archive/refs/tags/v%{version}.tar.gz
BuildArch:      noarch

BuildRequires:  make
BuildRequires:  sassc
BuildRequires:  glib2
Recommends:     gnome-shell-extension-user-theme
Recommends:     rsms-inter-fonts

%description
OhMyMac brings a macOS look to GNOME: traffic-light window controls,
macOS colours and geometry for GTK 3 and libadwaita apps, and a menu bar,
Control Center and Dock style for GNOME Shell. Run ohmymac-sync in your
session to keep GTK 3 and the Shell theme in step with light/dark mode.

%prep
%autosetup -n OhMyMac-%{version}

%build
make build

%install
make install DESTDIR=%{buildroot} PREFIX=%{_prefix}

%files
%license LICENSE
%doc README.md
%{_bindir}/ohmymac-sync
%{_datadir}/themes/OhMyMac-Light
%{_datadir}/themes/OhMyMac-Dark
%{_datadir}/ohmymac
%{_datadir}/backgrounds/ohmymac
%{_datadir}/gnome-background-properties/ohmymac.xml

%changelog
* Tue Oct 27 2026 cmpdchtr <cmpdchtr@gmail.com> - 1.0.0-1
- Initial package
