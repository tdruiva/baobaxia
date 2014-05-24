# !/bin/sh

# script de instalação do baobáxia
USER_BBX='exu'
USER_BBX_PASSWD='abre os caminhos'
UID_BBX=10000
BBX_DIR_NAME='bbx'
DEFAULT_REPOSITORY_DIR_NAME='repositories'
DEFAULT_MEDIA_ROOT='/data/bbx/'
DEFAULT_REPOSITORY_DIR=$DEFAULT_MEDIA_ROOT$DEFAULT_REPOSITORY_DIR_NAME
DEFAULT_REPOSITORY_NAME='mocambos'
INSTALL_DIR='/srv/bbx/'
LOG_DIR='log/'
BBX_LOCAL_REPO='/srv/bbx-repo'
BBX_REMOTE_REPO='http://github.com/RedeMocambos/baobaxia'

create_user() {
    USERNAME=$1
    USER_UID=$2
    # checa se usuario ja existe
    USER_EXISTS=`cat /etc/passwd | grep $USER_BBX`
    if [[ "$USER_EXISTS" == '' ]]; then
	echo "criando usuario $USER_BBX ..."
	useradd --uid $USER_UID --create-home -p "$EXU_PASSWD" $USERNAME
    fi
}


# PRE: pkgs:

# dependencies: se for deb pkg, tirar
apt-get install git git-annex nginx supervisor python-pip usbmount

### cria diretorio basico
mkdir -p $DEFAULT_REPOSITORY_DIR


# 1) escolha do nome da mucuaLocal
echo "------------------------"
echo "          /"
echo "    \_ \ /"
echo "      \ |  /___"
echo "  <==  \| /   ()"
echo "  ==>   ||    NPDD/Rede Mocambos"
echo "  nnn   ||/   "
echo "        ||    http://wiki.mocambos.net/wiki/NPDD"
echo "        ||    Vamos fazer um mundo digital mais do nosso jeito..."
echo "______/~~~~\_____________________________________________________________ _ _ _"
echo ""
echo " E ku abo ilê Baobáxia!"
echo " Bem vindo ao Baobáxia!"
echo " Welcome to Baobáxia!"
echo ""
echo "Esse é o instador do Baobáxia. "
echo ""
echo "----------------"
echo "Escolha o nome da sua mucua"
echo "----------------"
echo ""
read -p `hostname`" -> este é o nome da sua mucua? (s/n)" ESCOLHA
case "$ESCOLHA" in
    s|S) MUCUA=`hostname`;;
    n|N|*) read -p "Escolha o nome da mucua: " MUCUA ;;
esac
echo ""
echo "O nome da mucua é $MUCUA"
echo ""

echo "----------------"
echo " Escolha o endereço da sua mucua"
echo "----------------"
echo ""
MUCUA_URL=
read -p `hostname`".mocambos.net -> este é o url da sua mucua? (s/n)" ESCOLHA
case "$ESCOLHA" in
    s|S) MUCUA_URL=`hostname`".mocambos.net";;
    n|N|*) read -p "Escolha o url da mucua: " MUCUA_URL;;
esac
echo ""
echo "O url da mucua é $MUCUA_URL"
echo ""


echo ""
echo "Criando usuário padrão para o Baobáxia ..."
create_user $USER_BBX $UID_BBX

# define repositorioRemoto para espelhar / caminho do repositório 
echo "----------------"
echo "Defina um repositório remoto para espelhar:"
echo "----------------"
echo ""
echo "É possível conectar-se de diferentes formas a um repositório:"
echo "- pela rede (ssh)"
echo "- por um dispositivo externo: pendrive, hd externo (media)"
read -p "Como você vai conectar? (ssh/media, padrão é media)" PROTOCOL
case "$PROTOCOL" in
    # git clone via ssh
    ssh|SSH) PROTOCOL='ssh';
	echo "Acessar repositório via ssh..."
	read -p "Defina a url do repositório para espelhar (ex: zumbi.dandara.org):" MIRROR_REPOSITORY_NAME
	# TODO travar caso nao definir
	read -p "Defina a porta do repositório para espelhar (padrão: 22):" MIRROR_REPOSITORY_PORT
	case $MIRROR_REPOSITORY_PORT in
	    '') MIRROR_REPOSITORY_PORT=22 ;;
	esac
	read -p "Defina a pasta do repositório para espelhar (ex: /data/bbx/repositories/mocambos):" MIRROR_REPOSITORY_FOLDER
	git clone ssh://$USER_BBX@$MIRROR_REPOSITORY_NAME:$MIRROR_REPOSITORY_PORT/$MIRROR_REPOSITORY_FOLDER
	;;
    # git clone de media
    media|MEDIA|*) PROTOCOL='media' 
	echo ""
	echo "Conecte o drive externo ou pendrive."
	echo "Aperte ENTER quando inserir"
	read
	
	# TODO: travar até que o repositorio seja inserido
	# verificar se nos pontos de montagem ha algo que seja um hd de repositorio	
	IS_BBX_REPO=false
	for USB_DEVICE in `cat /proc/mounts  | grep usb | cut -d' ' -f2`; do	    
	    echo 'Dispositivo USB encontrado: '$USB_DEVICE
	    for REPO in `find $USB_DEVICE -name 'description' | grep .git`; do
		if [[ `cat $REPO` == "baobaxia" ]]; then
		    IS_BBX_REPO=true
		    REPO_NAME=$USB_DEVICE/`echo $REPO | cut -d '/' -f4`
		    break
		fi
	    done
	done;
	if [[ $IS_BBX_REPO == "" ]]; then
	    echo "Insira um dispositivo com um repositório válido."
	    exit 0
	fi

	echo ""
	echo "Espelhando repositório..."
	cd $DEFAULT_REPOSITORY_DIR
	git clone $REPO_NAME
	;;
esac

## configurar permissoes

echo ""
echo "Configurando permissões do repositório"
chown root:$USER_BBX $DEFAULT_REPOSITORY_DIR/$DEFAULT_REPOSITORY_NAME
chmod 775 $DEFAULT_REPOSITORY_DIR/$DEFAULT_REPOSITORY_NAME

echo ""
echo "Definindo usuário git para usuário do baobáxia ($USER_BBX) ..."
cd $DEFAULT_REPOSITORY_DIR/$DEFAULT_REPOSITORY_NAME
git config --global user.name "Exu do BBX"
git config --global user.email exu@mocambos.org
echo ""
echo "Criando novo repositório na mucua $MUCUA ..."
git init .
git annex init $MUCUA

# 5) criar diretórios locais 
echo ""
echo "Criando diretórios locais da mucua $MUCUA ..."
mkdir -p $DEFAULT_REPOSITORY_DIR/$DEFAULT_REPOSITORY_NAME/$MUCUA/mocambolas
mkdir -p $INSTALL_DIR/bin
mkdir -p $INSTALL_DIR/media
mkdir -p $INSTALL_DIR/static
mkdir -p $INSTALL_DIR/run
mkdir -p $INSTALL_DIR/log
mkdir -p $INSTALL_DIR/envs

echo ""
echo "Copiando arquivos do Baobáxia ..."
cd $INSTALL_DIR
# GARANTIR PERMISSAO DE GRAVACAO
# TODO: pegar futuramente um pacote offline

echo ""
read -p "De onde você vai baixar o repositório do baobáxia? (ex: http://github.com/RedeMocambos/baobaxia) - (1 - local / 2 - internet): " BBX_REPO_FROM
case "$BBX_REPO_FROM" in
    2|internet) BBX_REPO_FROM=$BBX_REMOTE_REPO ;;
    1|local|*) BBX_REPO_FROM=$BBX_LOCAL_REPO ;;
esac
git clone $BBX_REPO_FROM baobaxia

echo ""
echo "Criando arquivo de configuração do Baobáxia ..."
cp $INSTALL_DIR/baobaxia/app/django-bbx/bbx/settings.example.py $INSTALL_DIR/baobaxia/app/django-bbx/bbx/settings.py
sed -i -e '/REPOSITORY_DIR_NAME =/ s/= .*/= $DEFAULT_REPOSITORY_DIR_NAME/' $INSTALL_DIR/baobaxia/app/django-bbx/bbx/settings.py
sed -i -e '/MEDIA_ROOT =/ s/= .*/= $DEFAULT_MEDIA_ROOT/' $INSTALL_DIR/baobaxia/app/django-bbx/bbx/settings.py
sed -i -e '/DEFAULT_MUCUA =/ s/= .*/= $MUCUA/' $INSTALL_DIR/baobaxia/app/django-bbx/bbx/settings.py
sed -i -e '/DEFAULT_REPOSITORY =/ s/= .*/= $DEFAULT_REPOSITORY_NAME/' $INSTALL_DIR/baobaxia/app/django-bbx/bbx/settings.py


### instalacao do baobaxia
echo ""
echo "Criando ambiente virtual do python ..."
# cria ambiente virtual
pip install virtualenv
chown root:$USER_BBX $INSTALL_DIR/envs 
chmod 775 envs
xhost +
su - $USER_BBX -c "cd $INSTALL_DIR/envs"
su - $USER_BBX -c "virtualenv bbx"
su - $USER_BBX -c "source $INSTALL_DIR/envs/bbx/bin/activate"
su - $USER_BBX -c "cd $INSTALL_DIR/"
su - $USER_BBX -c "pip install $INSTALL_DIR/baobaxia.pybundle -r $INSTALL_DIR/baobaxia/app/django-bbx/requirements.txt"

echo ""
echo "Definindo permissões do baobáxia ..."
chown -R exu:exu $INSTALL_DIR/baobaxia

echo ""
echo "Criando banco de dados do baobáxia ..."
cd $INSTALL_DIR/baobaxia/app/django-bbx
find . -name '000*.py' -exec rm '{}' \; && echo "OK!"
python manage.py syncdb --noinput
python manage.py schemamigration --initial --traceback mocambola
python manage.py schemamigration --initial --traceback mucua
python manage.py schemamigration --initial --traceback tag
python manage.py schemamigration --initial --traceback media
python manage.py schemamigration --initial --traceback repository
python manage.py migrate --all
echo ""
echo "usuário do login número 1:"
echo "username: zumbi@$MUCUA.mocambos.net"
echo "senha: $USER_BBX_PASSWD"

echo ""
echo "Configurando o gunicorn ..."
cp $INSTALL_DIR/baobaxia/bin/gunicorn_start.sh.example $INSTALL_DIR/bin/gunicorn_start.sh
sed -i "s:_domain_:${BBX_DIR_NAME}:g" $INSTALL_DIR/bin/gunicorn_start.sh
chmod +x $INSTALL_DIR/bin/gunicorn_start.sh


# 7) recriar mucuas da rede no django-bbx (mucuaLocal)
# sync a partir dos jsons
echo ""
echo "Primeira sincronização, criando objetos a partir dos arquivos ..."
python manage.py create_objects_from_files


echo ""
echo "Criando arquivo de configuração do NGINX ..."
cp $INSTALL_DIR/baobaxia/conf/nginx/bbx /etc/nginx/site-available/bbx

sed -i "s:_domain_:${BBX_DIR_NAME}:g" /etc/nginx/site-available/bbx
sed -i "s:_domain_aliases_:${MUCUA} ${MUCUA_URL}:g" /etc/nginx/site-available/bbx

ln -s /etc/nginx/site-available/bbx /etc/nginx/site-enabled/bbx

echo ""
echo "Ativando NGINX ..."
service nginx restart

echo ""
echo "Criando arquivo de configuração do Supervisor ..."
cp $INSTALL_DIR/baobaxia/conf/supervisor/bbx /etc/supervisor/conf.d/bbx.conf

sed -i "s:_domain_:${BBX_DIR_NAME}:g" /etc/supervisor/conf.d/bbx.conf

echo ""
echo "Ativando o Baobáxia ..."
supervisorctl start bbx


echo "..."
echo "Instalação completa!"