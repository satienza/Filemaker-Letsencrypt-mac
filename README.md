# Let's Encrypt SSL Certificate Setup Script for FileMaker Server

This script automates the process of obtaining and installing an SSL certificate from the Let's Encrypt Certificate Authority (CA) for FileMaker Server. 

## Credit

This is a fork of the work started by: [David Nahodyl, Blue Feather](http://bluefeathergroup.com/blog/how-to-use-lets-encrypt-ssl-certificates-with-filemaker-server/)

## Prerequisites

Before running the script, ensure that Certbot is installed on your system. You can install Certbot from [https://certbot.eff.org](https://certbot.eff.org).

**WARNING: Ensure Certbot is installed before executing the script.**

## Usage

**WARNING: THIS SCRIPT WILL RESTART FILEMAKER SERVER!**

Ensure you have the necessary permissions to run this script as root.

### Options

- `-d | --domain`: Set the domain for which you want to obtain an SSL certificate.
- `-e | --email`: Set the contact email address for Let's Encrypt to reach you in case of issues.
- `-s | --server-path`: Set the path to your FileMaker Server directory (ending with a slash).
- `-p | --preferred-challenges`: Set the preferred verification mode. Choose between `http` (uses port 80) or `dns` (uses a TXT record in the domain DNS).
- `--no-confirm`: Skip confirmation (suggested for use in scripts).
- `-h, --help, --usage`: Print this help message.

### Example

```bash
./GetSSL.sh -d example.com -e your.email@example.com -s /path/to/FileMakerServer/ -p http
```

### Configuration

#### Domain (--domain)

Change the domain variable to the domain/subdomain for which you would like an SSL Certificate.

Example:

```bash
--domain "fms.mycompany.com"
```

#### Email

Change the contact email address to your real email address so that Let's Encrypt can contact you if there are any problems.

Example:

```bash
--email "myemail@mycompany.com"
```

#### Server Path (--server-path)

Enter the path to your FileMaker Server directory, ending with a slash.

Example:

```bash
--server-path "/Library/FileMaker Server/"
```

#### Preferred Challenges (--preferred-challenges)
Choose one of the following:
|Option|Description|Certbot Command|
|:-|:-|:-:|
| **http**| Uses port 80 through the server to verify the certificate. [_Default option_]|`standalone`|
| **dns**| Uses a TXT record in the domain DNS to verify the certificate. Use when you don't have access through port 80. In this case automatic renewal is not available. |`manual`|

##### Challenges
The `http` challenge uses the `standalone` mode and need an open 80 port through the server to validate your control of the domain.
The `dns` challenge will prompt you to place a DNS TXT record with specific contents under the domain name. You must do this before continuing with the process.

Check the [Certbot documentation](https://eff-certbot.readthedocs.io/en/stable/using.html) for the [standalone](https://eff-certbot.readthedocs.io/en/stable/using.html#standalone) or [manual](https://eff-certbot.readthedocs.io/en/stable/using.html#manual) commands.

Example:

```bash
--preferred-challenges http
```

### Installation

1. Ensure the script is executable:
    ```bash
    chmod +x GetSSL.sh
    ```

2. Run the script as root:
   ```bash
   sudo ./GetSSL.sh
   ````
