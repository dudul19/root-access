<div align="center">

## `🔓 Auto Create Root Access VPS 🌟` *

`made with 🤍 from Mr dudul`

---

**Aktifkan login root + password di VPS dengan satu perintah**

</div>

### Keterangan
- Script Bash untuk mengaktifkan login **root** dengan password dan mengganti password root VPS Linux secara otomatis.
- Berguna untuk VPS baru dari *cloud provider* (Biznet, AWS, Google Cloud, Azure, Oracle, DigitalOcean, dll) yang secara *default* menonaktifkan login root.

### Cara Pakai
- Login sebagai root dulu (`sudo su`).
- Jalankan perintah di bawah, lalu masukkan password root baru (2x).
- Simpan data IP, username, password, dan port yang muncul di akhir.

```bash
wget -qO root-access.sh https://raw.githubusercontent.com/dudul19/root-access/main/root-access.sh && bash root-access.sh
```

Atau dengan `curl`:

```bash
curl -fsSLo root-access.sh https://raw.githubusercontent.com/dudul19/root-access/main/root-access.sh && bash root-access.sh
```

### Yang Dilakukan Script
| Langkah | Keterangan |
|---|---|
| 📥 sshd_config | Menimpa `/etc/ssh/sshd_config` dengan [`sshd_config`](sshd_config) dari repo ini |
| 💾 Backup | Config lama disimpan ke `/etc/ssh/sshd_config.bak-<tanggal-jam>`, dikembalikan otomatis bila `sshd -t` gagal |
| 🔌 Port SSH | `22` `2222` `3369` `2269` `169` `99` |
| 🛡️ Firewall | Port dibuka otomatis di UFW / firewalld / SELinux bila aktif |
| 🔄 Restart SSH | Termasuk `ssh.socket` di Ubuntu 22.10+ |
| 🔑 Password | Mengganti password root, lalu menampilkan detail login |

### Sistem Operasi yang Didukung
| OS | Versi |
|---|---|
| Ubuntu | 18.04 – 26.04 |
| Debian | 9 – 13 |
| CentOS / AlmaLinux / Rocky Linux | semua versi dengan systemd |
| Lainnya | Linux dengan `systemd` dan `OpenSSH` |

### Donation
<div align="left">
  <a href="https://saweria.co/dudulrealnofek">
    <img src="https://img.shields.io/badge/Saweria-Donasi%20/%20Dukung%20Karya-F47C20?style=for-the-badge&logo=ko-fi&logoColor=white" alt="Saweria Donasi">
  </a>
</div>

#### Credit

 > - [MrDudul](https://t.me/dudulrealnofek)

<div align="center">

  `made with 🤍 from Mr Dudul`

</div>
