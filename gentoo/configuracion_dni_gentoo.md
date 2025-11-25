Aquí tienes todo correctamente en Markdown:

```markdown
# **Tutorial para usar el DNIe en Gentoo**

## **1. Instalación de los paquetes necesarios**
Asegúrate de tener los siguientes paquetes instalados:

```bash
sudo emerge app-crypt/opensc app-crypt/ccid sys-apps/pcsc-tools
```

- **`opensc`**: Biblioteca para trabajar con tarjetas inteligentes como el DNIe.
- **`ccid`**: Controladores para lectores de tarjetas inteligentes.
- **`pcsc-tools`**: Herramientas para diagnosticar y probar el sistema PC/SC.

---

## **2. Configuración de certificados**
1. **Descargar el certificado de la Autoridad Certificadora Raíz (AC Raíz) del DNIe:**
   - Ve al [Portal del DNIe](https://www.dnielectronico.es/PortalDNIe/PRF1_Cons02.action?pag=REF_076&id_menu=66).
   - Descarga el archivo **ACRAIZ-DNIE2.zip**.
   - Descomprime el archivo.

2. **Importar el certificado en Firefox:**
   - Abre Firefox y ve a:
     ```
     Configuración > Privacidad y seguridad > Certificados > Ver certificados > Autoridades > Importar
     ```
   - Selecciona el archivo `.crt` que has descomprimido.
   - Marca la opción para confiar en el certificado como autoridad para sitios web.

---

## **3. Configurar PKCS#11 en Firefox**
1. En Firefox, ve a:
   ```
   Configuración > Privacidad y seguridad > Certificados > Dispositivos de seguridad > Cargar
   ```
2. Introduce los siguientes valores:
   - **Nombre del módulo**: DNIe PKCS#11
   - **Ruta del módulo**: `/usr/lib64/opensc-pkcs11.so`  
     *(asegúrate de que esta ruta sea correcta para tu sistema; en sistemas de 32 bits sería `/usr/lib/opensc-pkcs11.so`)*.

3. Guarda la configuración.

---

## **4. Comprobar el lector de tarjetas inteligentes**
Asegúrate de que el lector de tarjetas está conectado y funcionando:

1. **Inicia el servicio `pcscd`:**
   ```bash
   sudo /etc/init.d/pcscd start
   ```
   Para que se inicie automáticamente con el sistema, puedes agregarlo al nivel de ejecución por defecto:
   ```bash
   sudo rc-update add pcscd default
   ```

2. **Verifica que el lector sea reconocido:**
   ```bash
   pcsc_scan
   ```
   Deberías ver información sobre tu lector de tarjetas. Inserta el DNIe para comprobar que es detectado.

