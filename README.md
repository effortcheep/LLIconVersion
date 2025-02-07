### how to use this

first you need install imagemagick

```shell
brew  install  imagemagick
```

add this shell to run script in xcode build phase
```shell
if [[ ! $PATH =~ /opt/homebrew/bin: ]] ; then 
  PATH=/opt/homebrew/bin/:/opt/homebrew/sbin:${PATH}
fi
$SRCROOT/LLIconVersion.sh
```

