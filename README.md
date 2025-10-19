# For Git & SSH managements (gsc & sshsc.sh)

This progect aim to create gsc(git script) and sshsc.sh(ssh script) for fix my pain point who has more than one Git account and using SSH to autherize.



## Contributing

Clone this repository to your local.
```
git clone https://github.com/kuranne/gsc-project
```
then **don't forgot** to config your username and email in ```kurannelib/gsc.config``` to use with `-A` option

### Recommend
Add gsc to $PATH to your .zshrc by setup yourself of use
```
cd gsc-project && ./setup.sh
```
then `source $HOME/.zshrc`

## Usages
common git add commit and push.
```
gsc -ac "commit message" -p
```
<br>
help

```
gsc -h
```

## Authors 
|name|position|
|-|-|
|[kuranne](https://www.github.com/kuranne)|pm, dev, tstr, qa, dp|
