# Installation:

```
nimble install inim
```

# Obligatory gif 

![image info](/img/repl.gif)



I highly recommend using the straight package manager

```
(straight-use-package
 '(inim
   :type git
   :host github
   :repo "serialdev/inim-mode"
   :config
   (add-hook inim-mode-hook #'evcxr-minor-mode)
))
```

Alternatively pull the repo and add to your init file
```
git clone https://github.com/SerialDev/inim-mode
```

## Hard Requirements
Inim is required 


# Current functionality:

```
C-c C-p [Start repl]
C-c C-b [Eval buffer]
C-c C-l [Eval line]
C-c C-r [eval region]
```

