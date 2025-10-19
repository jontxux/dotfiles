## Configuración de Red con systemd-networkd

### IP Estática

1. **Desactiva el servicio de networking antiguo:**
```bash
   sudo systemctl disable networking.service
   sudo systemctl stop networking.service
```

2. **Comenta la configuración en `/etc/network/interfaces`:**
```bash
   sudo nano /etc/network/interfaces
```
   Deja solo:
```
   # This file is not used anymore - using systemd-networkd instead
   # Configuration is in /etc/systemd/network/

   source /etc/network/interfaces.d/*

   auto lo
   iface lo inet loopback
```

3. **Crea la configuración de red:**
```bash
   sudo nano /etc/systemd/network/20-eth0.network
```
   Contenido (adapta interfaz, IP y gateway):
```ini
   [Match]
   Name=enp7s0

   [Network]
   Address=192.168.1.50/24
   Gateway=192.168.1.1
   DNS=1.1.1.1
   DNS=1.0.0.1
   DNS=9.9.9.9
   Domains=lan
   DHCP=no
```

4. **Ajusta permisos:**
```bash
   sudo chmod 644 /etc/systemd/network/20-eth0.network
```

5. **Habilita e inicia systemd-networkd:**
```bash
   sudo systemctl enable systemd-networkd
   sudo systemctl start systemd-networkd
```

6. **Verifica:**
```bash
   networkctl status
   ping -c 3 1.1.1.1
```

### systemd-resolved (DNS)

1. **Habilita e inicia el servicio:**
```bash
   sudo systemctl enable systemd-resolved
   sudo systemctl start systemd-resolved
```

2. **Configura el stub resolver:**
```bash
   sudo ln -sf /run/systemd/resolve/stub-resolv.conf /etc/resolv.conf
```

3. **Verifica:**
```bash
   resolvectl status
   resolvectl query google.com
```

### Limpieza (Opcional)

Si no necesitas el sistema antiguo:
```bash
sudo apt purge ifupdown
sudo apt autoremove
```
