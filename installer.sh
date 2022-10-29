#!/bin/bash

set -e
   clear

    echo ""
    echo "-------------------------------------------------------"
    echo "Refeito por: SrStellar ON#9695"
    echo "-------------------------------------------------------"
    echo "Observe que este script deve ser instalado em um sistema operacional novo. Instalá-lo em um sistema operacional não novo pode causar problemas."
    echo "-------------------------------------------------------"

    if [ "$lsb_dist" =  "ubuntu" ]; then
    echo "Esse script apenas funciona em sistemas operacionais Ubuntu."
    echo "-------------------------------------------------------"
    fi

install_options(){
    echo "Escolha o tipo de instalação:"
    echo "[1] Instalação completa do Dashactyl ( Dependencias, Arquivo, Configuração )"
    echo "[2] Instalar dependencias."
    echo "[3] Instalar arquivos."
    echo "[4] Configurar."
    echo "[5] Criar Certificados SSL ( Let'S Encrypt )"
    echo "[6] Criar e configurar um proxy reverso."
    echo "[7] Checar updates"
    echo "-------------------------------------------------------"
    read choice
    case $choice in
        1 ) installoption=1
            dependercy_install
            file_install
            settings_configuration
            reverseproxy_configuration
            ;;
        2 ) installoption=2
            dependercy_install
            ;;
        3 ) installoption=3
            file_install
            ;;
        4 ) installoption=4
            settings_configuration
            ;;
        5 ) installoption=5
            certificates_installation
            ;;
        6 ) installoption=6
            reverseproxy_configuration
            ;;
        7 ) installoption=7
            update_check
            ;;
        * ) output "Você não inseriu uma seleção válida."
            install_options
    esac
}

dependercy_install() {
    echo "------------------------------------------------------"
    echo "Iniciando instalação de dependencias."
    echo "------------------------------------------------------"
    sudo apt-get install nodejs
    sudo apt install npm
    sudo apt-get install git
    sudo apt update
    echo "-------------------------------------------------------"
    echo "Instalação de dependencias concluidas!"
    echo "-------------------------------------------------------"
}
file_install() {
    echo "-------------------------------------------------------"
    echo "Iniciando instalação de arquivos."
    echo "-------------------------------------------------------"
    cd /var/www/
    sudo git clone https://github.com/Votion-Development/Dashactyl.git
    cd Dashactyl
    sudo npm install
    sudo npm install forever -g
    echo "-------------------------------------------------------"
    echo "Instalação dos arquivos da dashboard concluidos!"
    echo "-------------------------------------------------------"
}
settings_configuration() {
    echo "-------------------------------------------------------"
    echo "Iniciando configurações."
    echo "-------------------------------------------------------"
    cd /var/www/Dashactyl/
    file=settings.json

    echo "Qual é a porta que a aplicação irá rodar? [80]"
    read WEBPORT
    echo "Qual é o Secret para o webserver?"
    read WEB_SECRET
    echo "Qual o dominio do seu painel pterodactyl? [paniel.seudominio.com]"
    read PTERODACTYL_DOMAIN
    echo "Qual é a key da api do seu painel pterodactyl?"
    read PTERODACTYL_KEY
    echo "Qual o id do seu bot, para oAuth2?"
    read DOAUTH_ID
    echo "Qual é o client secret do seu bot, para o oAuth2?"
    read DOAUTH_SECRET
    echo "Qual é o link de callback do oAuth2?"
    read DOAUTH_LINK
    echo "Qual será o endereço de callback? [callback]" 
    read DOAUTH_CALLBACKPATH
    echo "Prompt [TRUE/FALSE] (Quando definido como true, os usuários não precisarão fazer login novamente após uma sessão)"
    read DOAUTH_PROMPT
    sed -i -e 's/"port":.*/"port": '$WEBPORT',/' -e 's/"secret":.*/"secret": "'$WEB_SECRET'"/' -e 's/"domain":.*/"domain": "'$PTERODACTYL_DOMAIN'",/' -e 's/"key":.*/"key": "'$PTERODACTYL_KEY'"/' -e 's/"id":.*/"id": "'$DOAUTH_ID'",/' -e 's/"link":.*/"link": "'$DOAUTH_LINK'",/' -e 's/"path":.*/"path": "'$DOAUTH_CALLBACKPATH'",/' -e 's/"prompt":.*/"prompt": '$DOAUTH_PROMPT'/' -e '0,/"secret":.*/! {0,/"secret":.*/ s/"secret":.*/"secret": "'$DOAUTH_SECRET'",/}' $file
    echo "-------------------------------------------------------"
    echo "Configuracões completas!"
}
certificates_installation() {
    echo "Iniciando instalação de certificados."
    sudo apt install certbot
    echo "Certbot instalado."
    echo "-------------------------------------------------------"
    echo "Instalando extensão nginx."
    sudo apt install certbot-python3-nginx
    echo "Extensão Certbot nginx"
    echo ""
    echo ""
    echo "Escreva abaixo o seu dominio [ ex: dash.seudominio.com ]: "
    read DOMINIO
    echo "Digite abaixo um email para o sistema."
    read EMAIL
    echo "Criando certificados para seu dominio."
    sudo certbot certonly --nginx -d $DOMINIO --email $EMAIL
    echo "Seu certificado foi gerado com sucesso."
}

reverseproxy_configuration() {
    echo "-------------------------------------------------------"
    echo "Starting Reverse Proxy Configuration."
    echo "Read the Docs for more infomration about the Configuration."
    echo "-------------------------------------------------------"

   echo "Selecione o webserver [NGINX]"
   read WEBSERVER
   echo "Protocolo [HTTPS]"
   read PROTOCOL
   if [ $PROTOCOL != "HTTPS" ]; then
   echo "------------------------------------------------------"
   echo "Apenas HTTPS é suportado."
   echo "------------------------------------------------------"
   return
   fi
   if [ $WEBSERVER != "NGINX" ]; then
   echo "------------------------------------------------------"
   echo "Abortado, apenas Nginx é suportado para o proxy reveso."
   echo "------------------------------------------------------"
   return
   fi
   echo "Qual o seu dominio? [example.com]"
   read DOMAIN
   apt install nginx
   sudo wget -O /etc/nginx/sites-enabled/dashactyl.conf https://raw.githubusercontent.com/SrStellar/Dashactyl-Installer/main/assets/nginx.conf
   sudo apt-get install jq 
   port=$(jq -r '.["website"]["port"]' /var/www/Dashactyl/settings.json)
   sed -i 's/PORT/'$port'/g' /etc/nginx/sites-enabled/dashactyl.conf
   sed -i 's/DOMAIN/'$DOMAIN'/g' /etc/nginx/sites-enabled/dashactyl.conf
   sudo nginx -t
   sudo nginx -s reload
   systemctl restart nginx
   echo "-------------------------------------------------------"
   echo "Instalação do reverse proxy concluida."
   echo "-------------------------------------------------------"
   echo "Here is the config status:"
   sudo nginx -t
   echo "-------------------------------------------------------"
   echo "Nota: se na linha abaixo não estiver escrito OK, alguma coisa deu errado, entre em contato no Discord de Suporte do Dashactyl."
   echo "-------------------------------------------------------"
   if [ $WEBSERVER = "APACHE" ]; then
   echo "Apache isn't currently supported with the install script."
   echo "------------------------------------------------------"
   return
   fi
}
update_check() {
    latest=$(wget https://raw.githubusercontent.com/SrStellar/Dashactyl-Installer/main/assets/latest.json -q -O -)
    #latest='"version": "0.1.2-themes6",'
    version=$(grep -Po '"version":.*?[^\\]",' /var/www/dashactyl/settings.json) 

    if [ "$latest" =  "$version" ]; then
    echo "-------------------------------------------------------"
    echo "Você está na ultima versão do Dashactyl."
    echo "-------------------------------------------------------"
    else 
    echo "Você está rodando em uma versão antiga do Dashactyl."
    echo "-------------------------------------------------------"
    echo "Você gostaria de atualizar sua Dashboard? [Y/N]"
    echo "Um backup será criado em: /var/www/dashactyl-backup/"
    read UPDATE_OPTION
    echo "-------------------------------------------------------"
    if [ "$UPDATE_OPTION" = "Y" ]; then
    var=`date +"%FORMAT_STRING"`
    now=`date +"%m_%d_%Y"`
    now=`date +"%Y-%m-%d"`
    if [[ ! -e /var/www/dashactyl-backup/ ]]; then
    mkdir /var/www/dashactyl-backup/
    finish_update
    elif [[ ! -d $dir ]]; then
    finish_update
    fi
    else
    echo "Update Aborted"
    echo "Restart the script if this was a misstake."
    echo "-------------------------------------------------------"
    fi
    fi
}
finish_update() {
   tar -czvf "${now}.tar.gz" /var/www/dashactyl/
   mv "${now}.tar.gz" /var/www/dashactyl-backup
   rm -R /var/www/dashactyl/
   file_install
}
install_options