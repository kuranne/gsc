
# Git & SSH managements

This progect aim to create gsc(git script) and sshsc.sh(ssh script) for fix my pain point who has more than one Git account and using SSH to autherize.



## Contributing

- To use gsc, you can clone this repository into your directory by:
``` bash
git clone git@github.com:kuranne/myShScript
```
- After did that, for comfort to run the script you may put
```bash
cd myShScript
echo 'export PATH="$(pwd):${PATH}"' >> $HOME/.zshrc
```
- Then reopen your shell or use
```bash
source $HOME/.zshrc
```
And All Done! try to use this to show the option gsc have
```bash
gsc -h
```


## Authors
- [@kuranne](https://www.github.com/kuranne)
