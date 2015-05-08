#!/bin/bash
echo -e "\e[37;1m Instalador do OwnCloud - by Fabio Pimenta \e[m";
sleep 1;
#Verificacao de permissao de root
echo -n "Verificando se usuario tem permissoes";
if [ `whoami` != 'root' ]; then 
	echo -e "\e[31;1m [Erro] \e[m";
	echo -e "\e[31;1m Necessario ser root \e[m";
	exit 1;
fi
echo -e "\e[32;1m [OK] \e[m";
sleep 1;
#Verificar se existe internet
echo -n "Verificando acesso com a internet":
if ! ping -c 2 registro.br >> /dev/null ; then
	echo -e "\n\e[31;1m Sem internet \e[m";
	echo " Nao sera possivel continuar...":
	exit 1;
fi
echo -e "\e[32;1m [OK] \e[m";
sleep 1;
#Instalacao dos pacotes necessarios
echo -n "Verificando se os pacotes requeridos existem";
D=`which dialog wget vim 2> /dev/null`;
if [ $? != 0 ];then
	echo -e "\e[31;1m [Falha] \e[m";
	echo -e "\e[33;1m Instalando os pacotes necessarios \e[m";
	sleep 1;
	yum install -y dialog wget vim >> /dev/null;
	echo -e "\e[32;1m [OK] \e[m";
else
	echo -e "\e[32;1m [OK] \e[m";
fi
sleep 1;
#Atualizacao do sistema
dialog --title "Confirmar Atualizacao" --yesno "Iniciar atualizacao?" 0 0;
if [ $? = 0 ];then
	yum update -y >> /dev/null;
	echo -e "\e[32;1m [OK] \e[m";
else
	echo -e "\e[32;1m [Pulando atualizacao] \e[m";
fi
sleep 1;
#Confirmar a operacao
dialog --title "Iniciando o processo" --yesno "Iniciar as instalacoes?" 0 0;
if [ $? != 0 ];then
	echo -e "\e[31;1m [Finalizado pelo usuario] \e[m";
	exit 1;
fi
sleep 1;
#Adicionando o repositorio do owncloud
echo -n "Adicionando o Repositorio do OwnCloud";
P=`pwd`;
cd /etc/yum.repos.d/
if [ ! -f "/etc/yum.repos.d/isv:ownCloud:community.repo" ]; then
	wget -q http://download.opensuse.org/repositories/isv:ownCloud:community/CentOS_CentOS-7/isv:ownCloud:community.repo;
else
	echo -e "\e[34;1m [Repositorio ja existe] \e[m";
fi
if [ $? = 0 ]; then
	echo -e "\e[32;1m [OK] \e[m";
	cd $P;
else
	echo -e "\e[31;1m [Falha ao baixar o repositorio] \e[m";
	cd $P;
	exit 1;
fi
sleep 1;
#instalando os pacotes necessarios
echo -n "Adicionando os pacotes necessarios";
yum install owncloud mariadb-server php-mysqlnd mod_ssl -y >> dev/null;
if [ $? = 0 ]; then
	echo -e "\e[32;1m [OK] \e[m";
else
	echo -e "\e[31;1m [Falha] \e[m";
	exit 1;
fi
sleep 1;
#ajustando as permissoes da pasta do cloud
echo -n "Ajustando as permissoes de pasta  do OwnCloud";
ajusta_permissoes()
{
	ocpath='/var/www/html/owncloud';
	htuser='apache';
	cp ${ocpath}/.htaccess ${ocpath}/data/.htaccess;
	if [ $? != 0 ]; then echo -e "\e[31;1m [Falha] \e[m"; exit 1; fi;
	find ${ocpath}/ -type f -print0 | xargs -0 chmod 0640;
	if [ $? != 0 ]; then echo -e "\e[31;1m [Falha] \e[m"; exit 1; fi;
	find ${ocpath}/ -type d -print0 | xargs -0 chmod 0750;
	if [ $? != 0 ]; then echo -e "\e[31;1m [Falha] \e[m"; exit 1; fi;
	chown -R root:${htuser} ${ocpath}/;
	if [ $? != 0 ]; then echo -e "\e[31;1m [Falha] \e[m"; exit 1; fi;
	chown -R ${htuser}:${htuser} ${ocpath}/apps/;
	if [ $? != 0 ]; then echo -e "\e[31;1m [Falha] \e[m"; exit 1; fi;
	chown -R ${htuser}:${htuser} ${ocpath}/config/;
	if [ $? != 0 ]; then echo -e "\e[31;1m [Falha] \e[m"; exit 1; fi;
	chown -R ${htuser}:${htuser} ${ocpath}/data/;
	if [ $? != 0 ]; then echo -e "\e[31;1m [Falha] \e[m"; exit 1; fi;
	chown root:${htuser} ${ocpath}/.htaccess;
	if [ $? != 0 ]; then echo -e "\e[31;1m [Falha] \e[m"; exit 1; fi;
	chown root:${htuser} ${ocpath}/data/.htaccess;
	if [ $? != 0 ]; then echo -e "\e[31;1m [Falha] \e[m"; exit 1; fi;
	chmod 0644 ${ocpath}/.htaccess;
	if [ $? != 0 ]; then echo -e "\e[31;1m [Falha] \e[m"; exit 1; fi;
	chmod 0644 ${ocpath}/data/.htaccess;
	if [ $? != 0 ]; then echo -e "\e[31;1m [Falha] \e[m"; exit 1; fi;
	chcon -vR --type=httpd_sys_rw_content_t /var/www/html/owncloud;
	if [ $? != 0 ]; then echo -e "\e[31;1m [Falha] \e[m"; exit 1; fi;
	systemctl enable mariadb;
	if [ $? != 0 ]; then echo -e "\e[31;1m [Falha] \e[m"; exit 1; fi;
	systemctl enable httpd;
	if [ $? != 0 ]; then echo -e "\e[31;1m [Falha] \e[m"; exit 1; fi;
	firewall-cmd --permanent --add-port=80/tcp;
	if [ $? != 0 ]; then echo -e "\e[31;1m [Falha] \e[m"; exit 1; fi;
	firewall-cmd --permanent --add-port=443/tcp;
	if [ $? != 0 ]; then echo -e "\e[31;1m [Falha] \e[m"; exit 1; fi;
	firewall-cmd --reload;
	if [ $? != 0 ]; then echo -e "\e[31;1m [Falha] \e[m"; exit 1; fi;
}
ajusta_permissoes >> /dev/null;
echo -e "\e[32;1m [OK] \e[m";
#iniciando o banco de dados
echo -n "Iniciando o MariaDB";
systemctl start mariadb;
if [ $? != 0 ]; then echo -e "\e[31;1m [Falha] \e[m"; exit 1; fi;
echo -e "\e[32;1m [OK] \e[m";
#chamando o mysql_secure_installation
echo -n "Chamando o mysql_secure_installation":
mysql_secure_installation;
if [ $? != 0 ]; then echo -e "\e[31;1m [Falha] \e[m"; exit 1; fi;
echo -e "\e[32;1m [OK] \e[m";
sleep 1;
#criando a tabela
echo -n "Criando a tabela":
sleep 1;
TABELA=$(dialog --stdout --inputbox "Nome da nova tabela do banco"  0 0 "owncloud");
if [ -z "$TABELA" ]; then echo -e "\e[31;1m [Falta o nome da nova tabela] \e[m"; exit 1; fi;
USUARIO=$(dialog --stdout --inputbox "Nome do novo usuario do banco"  0 0 "owncloud");
if [ -z "$USUARIO" ]; then echo -e "\e[31;1m [Falta o nome do novo usuario] \e[m"; exit 1; fi;
SENHA=$(dialog --stdout --passwordbox "Senha do novo usuario do banco" 0 0);
if [ -z "$SENHA" ]; then echo -e "\e[31;1m [Falta a senha do novo usuario] \e[m"; exit 1; fi;
DBPASS=$(dialog --stdout --passwordbox "[*** Senha de root do MariaDB ***]" 0 0);
if [ -z "$DBPASS" ]; then echo -e "\e[31;1m [Falta a senha de root do banco] \e[m"; exit 1; fi;
#verifica se o usuario ja existe
U=`mysql -u root -p"$DBPASS" -e "select user,host from mysql.user where user='cloud';"`;
if [ ! -z "$U" ]; then
	echo -e "\e[34;1m [Usuario ja existe] \e[m";
else
	CMD="CREATE USER '$USUARIO'@'localhost' IDENTIFIED BY '$SENHA';";
	mysql -u root -p"$DBPASS" -e "$CMD";
	if [ $? != 0 ]; then echo -e "\e[31;1m [Falha] \e[m"; exit 1; fi;
	echo -e "\e[32;1m [OK] \e[m";
fi
echo -n "Criando os privilegios":
CMD="GRANT ALL PRIVILEGES ON $TABELA.* TO '$USUARIO'@'localhost' WITH GRANT OPTION;";
mysql -u root -p"$DBPASS" -e "$CMD";
if [ $? != 0 ]; then echo -e "\e[31;1m [Falha] \e[m"; exit 1; fi;
echo -e "\e[32;1m [OK] \e[m";
echo -n "Flush":
CMD="FLUSH PRIVILEGES;";
mysql -u root -p"$DBPASS" -e "$CMD";
if [ $? != 0 ]; then echo -e "\e[31;1m [Falha] \e[m"; exit 1; fi;
echo -e "\e[32;1m [OK] \e[m";
echo -e "\e[33;1m [Processo finalizado com sucesso] \e[m";
