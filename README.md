# Vamos Construir um Compilador em Common Lisp

Este repositorio contem um site estatico bilingue e um pequeno compilador
funcional, tudo escrito em Common Lisp.

O site e uma adaptacao original em Common Lisp inspirada pelo caminho classico
de aulas sobre construcao de compiladores. Ele nao reproduz o texto original do
curso. O ingles e o idioma principal do site, e pt-BR esta disponivel como uma
versao localizada gerada.

## Abrir o Site

Depois de construir o site, abra:

- Ingles: `public/index.html`
- pt-BR: `public/pt-br/index.html`

Cada pagina gerada tem um seletor `EN` / `PT-BR` que aponta para a pagina
correspondente no outro idioma.

## Estrutura do Projeto

- `src/tiny-compiler.lisp`: compilador Tiny autocontido, parser, compilador para
  bytecode e VM de pilha.
- `src/content.lisp`: dados das licoes em ingles e exemplos Common Lisp
  testados.
- `src/content-pt-br.lisp`: texto das licoes em pt-BR, compartilhando os mesmos
  exemplos de codigo testados.
- `src/render.lisp`: renderizador do site estatico em Common Lisp e gerador do
  asset PNG.
- `build.lisp`: constrói o site estatico em `public/`.
- `test.lisp`: roda os testes do compilador, exemplos, localizacao e geracao do
  site.

## Construir

```sh
sbcl --script build.lisp
```

O build escreve as paginas em ingles em `public/`, as paginas pt-BR em
`public/pt-br/` e os assets compartilhados em `public/assets/`.

## Testar

```sh
sbcl --script test.lisp
```

A suite de testes verifica:

- scanner, parser, geracao de bytecode e comportamento da VM;
- todos os exemplos Common Lisp exibidos nas licoes em ingles e pt-BR;
- o caminho da fonte completa do compilador;
- geracao bilingue do site.

## Rodar o Compilador Tiny Isoladamente

`src/tiny-compiler.lisp` pode rodar sem carregar o site, os arquivos de conteudo
ou o arquivo de pacote.

Rode a demo embutida de fatorial:

```sh
sbcl --script src/tiny-compiler.lisp
```

Rode um programa Tiny passado pela linha de comando:

```sh
sbcl --script src/tiny-compiler.lisp "print 2 + 3 * 4;"
```

Carregue o compilador independentemente a partir de um REPL ou outro script:

```lisp
(load "src/tiny-compiler.lisp")
(lbccl.compiler:run-source "print 40 + 2;")
```

## Resumo da Linguagem Tiny

Tiny suporta aritmetica inteira, variaveis, atribuicao, `print`, `if`/`else` e
`while`.

```text
let n = 5;
let acc = 1;
while n > 1 do
  acc = acc * n;
  n = n - 1;
end
print acc;
```

O compilador emite bytecode para uma pequena VM de pilha e retorna a saida
impressa como uma lista Common Lisp.

## Publicar no GitHub Pages

Este site e gerado em `public/`, entao o caminho recomendado e usar GitHub
Actions para rodar os testes, construir o site e publicar o diretorio gerado no
GitHub Pages.

Fluxo basico:

```sh
git init
git add .
git commit -m "Site do compilador em Common Lisp"
git branch -M main
git remote add origin https://github.com/SEU_USUARIO/NOME_DO_REPOSITORIO.git
git push -u origin main
```

Depois, configure `Settings` -> `Pages` -> `Build and deployment` -> `Source`
como `GitHub Actions` e adicione um workflow que rode:

```sh
sbcl --script test.lisp
sbcl --script build.lisp
```

O artifact publicado deve ser o diretorio `public/`.

website: https://edencompiler.github.io/Vamos-Construir-um-Compilador-em-Common-Lisp/
