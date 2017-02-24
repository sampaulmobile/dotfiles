
RUBY_VER=2.2.5
USERNAME=sampaul
DOC_PATH=$HOME/Development/Docurated
NOT_PUBLIC=/Users/sampaul/dropbox/!public


echo "Setting up repos..."
mkdir -p $DOC_PATH

if [ ! -d $DOC_PATH/website ]; then
    echo "Cloning website..."

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

    # link up site_config/database.yml
    rm $RAILS/config/database.yml
    rm $RAILS/config/siteconfig.yml
    ln -s $NOT_PUBLIC/links/database.yml $RAILS/config/database.yml
    ln -s $NOT_PUBLIC/links/siteconfig.yml $RAILS/config/siteconfig.yml
    createdb -h localhost -p 5432 -U $USERNAME docurated
    createdb -h localhost -p 5432 -U $USERNAME docurated_test

    # run db:migrate twice because of that sfModifiedOpp issue
    rake db:migrate
    rake db:migrate
    echo "Docurated::Application.config.secret_token = '`rake secret`'" > $RAILS/config/initializers/secret_token.rb
    # open rails console, execute
    # o = Organization.create(name: "Docurated", domain: "docurated.com")
    # u = User.new(first_name: "Sam", last_name: "Paul", organization_id: 1, password: 'asdfasdf', email: "sam@docurated.com", confirmed: true)
    # u.confirm!
    # u.save validate:false
    # u.toggle!(:admin)
fi

if [ ! -d $DOC_PATH/activity ]; then
    git clone git@github.com:Docurated/activity.git $DOC_PATH/activity
    git remote set-url origin ssh://git@phabricator.docurated.rocks:2222/diffusion/ACT/activity.git
fi

if [ ! -d $DOC_PATH/services ]; then
    git clone git@github.com:Docurated/services.git $DOC_PATH/services
fi

if [ ! -d $DOC_PATH/utilities ]; then
    git clone git@github.com:Docurated/utilities.git $DOC_PATH/utilities
    cd $DOC_PATH/utilities
    git remote set-url origin ssh://git@phabricator.docurated.rocks:2222/diffusion/UTL/utilities.git

    brew install terraform
    cd $DOC_PATH/utilities/terraform
    terraform remote config -backend=s3 -backend-config="bucket=docurated-ops" -backend-config="key=terraform/terraform.tfstate"
    terraform get
fi

# cd $HOME/Development/Docurated/utilities/docformation
# echo $RUBY_VER@utilities > .ruby-version

