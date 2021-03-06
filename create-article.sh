#! /bin/bash

# Need to add attachments


# Get user configs from `configs` file, unset other variables, choose article type, name, and working directory
. configs
unset TEMPLATE FILE NAME SNAME 
case $1 in
    -q | --question )   TEMPLATE=question
                        ;;
    -i | --issue )      TEMPLATE=issue
                        ;;
    -h | --howto )      TEMPLATE=how-to
                        ;;
esac
shift
NAME=${1?What is the name of your article}
WD=$PWD

#use GNU sed and readlink on macos
if [[ "$OSTYPE" == "darwin"* ]]; then
  SED_CMD='gsed'
  READLINK_CMD='greadlink'
else
  SED_CMD='sed'
  READLINK_CMD='readlink'
fi

# slugify the name
slugify () {
  echo "$1" |
  iconv -t ascii//TRANSLIT |
  $SED_CMD -r s/[^a-zA-Z0-9]+/-/g |
  $SED_CMD -r s/^-+\|-+$//g |
  tr A-Z a-z
}
SNAME="$(slugify "$NAME")"


# Refresh the repo and create feature branch
echo "refreshing repo and creating feature branch for $SNAME"
cd ../support-kb
git fetch upstream
git rebase upstream/master
git checkout -b "$SNAME"


# Declare folder and file variables
FOLDER="$($READLINK_CMD -f kbase/knowledge-base/$TEMPLATE/$SNAME)"
FILE="$FOLDER/README.md"


# Create folder and __article__.yaml file
mkdir $FOLDER
echo "name: $NAME" > $FOLDER/__article__.yaml
echo "author: $AUTHOR" >> $FOLDER/__article__.yaml
echo "visibility: $VIS" >> $FOLDER/__article__.yaml
echo "draft: false" >> $FOLDER/__article__.yaml


# Write the article
cp ../support-kb/templates/$TEMPLATE/README.md "$FOLDER/README.md"

echo "created and populated $($READLINK_CMD -f kbase/knowledge-base/$TEMPLATE/$SNAME) with template.  Opening file in system default editor"
${VISUAL:-${EDITOR:-vi}} $FILE

# Stage changes to the article and finish 
git add $FOLDER
git commit -m \"Add article: $NAME\"
git push origin $SNAME

echo "##########################################################"
echo "Done editing.  Changes have been commited and pushed to your fork-branch. You can now add attachments or make changes before committing and pushing or just create another article and come back to this branch later."
echo
echo "You can now resync to the main KB branch by running ./reset-to-upstream.sh and/or file your pull request from github"
