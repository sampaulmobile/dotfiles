#!/bin/bash

RUBY_VER=2.2.5
DOC_PATH=$HOME/Development/Docurated
NOT_PUBLIC=$HOME/Dropbox/!public

sudo -v
mkdir -p $DOC_PATH


# WEBSITE
echo "Setting up website..."
if [ ! -d $DOC_PATH/website ]; then
    git clone git@github.com:Docurated/website.git $DOC_PATH/website

    RAILS=$DOC_PATH/website/rails

    echo $RUBY_VER@website > $RAILS/.ruby-version
    cd $RAILS
    brew install imagemagick@6
    brew link --force imagemagick@6
    brew uninstall v8
    gem install therubyracer -v '0.12.1'
    brew install v8
    gem install libv8 -v '3.16.14.7' -- --with-system-v8
    gem install eventmachine -v '1.0.4' -- --with-cppflags=-I/usr/local/opt/openssl/include
    gem install bundler
    bundle install

    createdb -h localhost -p 5432 -U $USERNAME docurated
    createdb -h localhost -p 5432 -U $USERNAME docurated_test

    # run db:migrate twice because of that sfModifiedOpp issue
    rake db:migrate
    rake db:migrate
    echo "Docurated::Application.config.secret_token = '`rake secret`'" > $RAILS/config/initializers/secret_token.rb

    cat > temp.rb <<EOL
o = Organization.create(name: "Docurated", domain: "docurated.com")
u = User.new(first_name: "Sam", 
            last_name: "Paul", 
            organization_id: o.id, 
            password: 'asdfasdf', 
            email: "sam@docurated.com", 
            confirmed: true)
u.confirm!
u.save validate:false
u.toggle!(:admin)

OrganizationsSolrCluster.delete_all
OrganizationsSolrCluster.create(
    organization_id: o.id,
    is_primary: true,
    cluster_url: "localhost:9983",
    in_zookeeper: true,
    transformation: "SchemaTwoSpacesTileDocCreator")
EOL
    bundle exec rails runner "eval(File.read 'temp.rb')"
    rm temp.rb

    sudo -- sh -c 'echo "" >> /etc/hosts'
    sudo -- sh -c 'echo "#dev for docurated" >> /etc/hosts'
    sudo -- sh -c 'echo "127.0.0.1       development.docurated.com" >> /etc/hosts'
fi
ln -Fs $NOT_PUBLIC/links/database.yml $DOC_PATH/website/rails/config/database.yml
ln -Fs $NOT_PUBLIC/links/siteconfig.yml $DOC_PATH/website/rails/config/siteconfig.yml
cd $DOC_PATH/website
git remote set-url origin ssh://git@phabricator.docurated.rocks:2222/diffusion/WEB/website.git


# ACTIVITY
echo "Setting up activity..."
if [ ! -d $DOC_PATH/activity ]; then
    git clone git@github.com:Docurated/activity.git $DOC_PATH/activity
fi
cd $DOC_PATH/activity
git remote set-url origin ssh://git@phabricator.docurated.rocks:2222/diffusion/ACT/activity.git


# SERVICES
echo "Setting up services..."
if [ ! -d $DOC_PATH/services ]; then
    git clone git@github.com:Docurated/services.git $DOC_PATH/services
fi
cd $DOC_PATH/services
git remote set-url origin ssh://git@phabricator.docurated.rocks:2222/diffusion/SVC/services.git

if [ ! -d /usr/local/lib/jmagick ]; then
    git clone git@github.com:techblue/jmagick.git $HOME/Downloads/jmagick

    sudo mkdir -p /usr/local/lib/jmagick/lib
    cd $HOME/Downloads/jmagick
    IMAGE_MAGICK=`brew list | grep image`
    IMAGE_MAGICK_VER=`ls /usr/local/Cellar/$IMAGE_MAGICK`
    IMAGE_MAGICK_PATH="/usr/local/Cellar/$IMAGE_MAGICK/$IMAGE_MAGICK_VER"

    JAVA_FW_HOME=/System/Library/Frameworks/JavaVM.framework/Versions/Current
    ./configure --with-java-home=$JAVA_FW_HOME --with-magick-home=$IMAGE_MAGICK_PATH --prefix=/usr/local/lib/jmagick
    sudo make all
    sudo make install
    sudo ln -s /usr/local/lib/jmagick/lib/libJMagick-*.so /Library/Java/Extensions/libJMagick.jnilib
    sudo ln -s /usr/local/lib/jmagick/lib/libJMagick-*.so /usr/local/lib/jmagick/lib/libJMagick.jnilib

    rm -rf $HOME/Downloads/jmagick
fi

sudo mkdir -p /var/run/jworker/pids
sudo mkdir -p /var/log/jworker
touch /var/run/jworker/sqs.poll
sudo chown -R $USERNAME:staff /var/run/jworker
sudo chown -R $USERNAME:staff /var/log/jworker

SERV_COMMON=$DOC_PATH/services/javaworker/common/src/main/resources
SERV_MASTER=$DOC_PATH/services/javaworker/master/src/main/resources

ln -Fs $NOT_PUBLIC/links/config.groovy $SERV_COMMON/config.groovy
ln -Fs $NOT_PUBLIC/links/hibernate.properties $SERV_COMMON/hibernate.properties
cp $SERV_COMMON/log4j.default.properties $SERV_COMMON/log4j.properties
cp $SERV_MASTER/application.default.conf $SERV_MASTER/application.conf


# UTILITIES
echo "Setting up utilities..."
if [ ! -d $DOC_PATH/utilities ]; then
    git clone git@github.com:Docurated/utilities.git $DOC_PATH/utilities

    cd $DOC_PATH/utilities/terraform
    terraform remote config -backend=s3 -backend-config="bucket=docurated-ops" -backend-config="key=terraform/terraform.tfstate"
    terraform get
fi
cd $DOC_PATH/utilities
git remote set-url origin ssh://git@phabricator.docurated.rocks:2222/diffusion/UTL/utilities.git


# KUBERNETES
echo "Setting up kubernetes..."
if [ ! -d $DOC_PATH/utilities ]; then
    git clone ssh://git@phabricator.docurated.rocks:2222/diffusion/KUBE/kubernetes.git
fi


