(in-package #:lbccl.content)

(defparameter *course-title-pt-br*
  "Vamos Construir um Compilador em Common Lisp")

(defparameter *course-deck-pt-br*
  "Um curso original em Common Lisp inspirado pelo caminho classico de construcao de compiladores: comece com expressoes pequenas, cresca um scanner e um parser, emita bytecode e mantenha a implementacao legivel.")

(defparameter *available-languages* '(:en :pt-br))

(defparameter *pt-br-lesson-translations*
  '((:title "Introducao"
     :deck "Construa um compilador fazendo primeiro a menor parte util funcionar."
     :goals ("Veja a linguagem fonte, o compilador, o bytecode e a VM como um unico ciclo de feedback."
             "Use dados de Common Lisp como uma representacao pratica da AST."
             "Compile e execute um primeiro programa Tiny.")
     :sections
     ((:heading "A forma do projeto"
       :paragraphs ("Este curso e uma adaptacao original em Common Lisp, nao uma reproducao do texto de Jack Crenshaw. Ele segue o mesmo habito util: digitar pecas pequenas, executa-las e manter o compilador compreensivel."
                    "O exemplo completo deste site compila uma linguagem Tiny para bytecode de uma VM de pilha. Isso deixa a geracao de codigo concreta sem exigir assembler ou toolchain nativa."))
      (:heading "Por que Common Lisp encaixa bem"
       :paragraphs ("Um compilador e, em grande parte, construcao e caminhada de arvores. Common Lisp oferece dados simbolicos, sequencias genericas, restarts no REPL e iteracao rapida."
                    "Na primeira passada, listas simples bastam. Os capitulos posteriores mostram onde estruturas, classes ou passes separados comecariam a valer a pena."))))
    (:title "Analise de Expressoes"
     :deck "Transforme texto aritmetico em uma arvore com descida recursiva."
     :goals ("Analise literais, parenteses, operadores unarios e precedencia."
             "Represente expressoes como S-expressions simples."
             "Compile arvores de expressao para operacoes de pilha.")
     :sections
     ((:heading "Descida recursiva em uma ideia"
       :paragraphs ("Cada nivel de precedencia ganha uma funcao. O parser de expressoes chama o parser de relacoes, que chama adicao, depois multiplicacao, depois unario e depois primario."
                    "O resultado e um codigo parecido com a gramatica e facil de depurar no REPL."))
      (:heading "Codigo de pilha para expressoes"
       :paragraphs ("Uma maquina de pilha deixa o primeiro gerador de codigo pequeno. Compile a expressao da esquerda, compile a da direita e depois emita a instrucao do operador.")
       :notes ("Tente compilar 2 + 3 * 4 e confirme que a multiplicacao aparece antes da adicao na AST."))))
    (:title "Mais Expressoes"
     :deck "Adicione variaveis, atribuicao, menos unario e comparacoes."
     :goals ("Diferencie nomes de palavras-chave."
             "Trate variaveis como cargas e armazenamentos."
             "Retorne inteiros para respostas booleanas para que condicoes possam desviar.")
     :sections
     ((:heading "Variaveis sao posicoes no ambiente"
       :paragraphs ("A primeira implementacao nao precisa de uma tabela de simbolos com escopos. Uma hash table de nome de variavel para valor inteiro basta para a VM, e o compilador ainda pode emitir instrucoes explicitas de load e store."))
      (:heading "Comparacoes sao expressoes"
       :paragraphs ("Uma comparacao e compilada exatamente como a aritmetica: calcule os dois lados e emita uma operacao. A VM empilha 1 para verdadeiro e 0 para falso, o que simplifica o fluxo de controle posterior."))))
    (:title "Interpretadores"
     :deck "Execute o bytecode compilado com uma pequena maquina virtual."
     :goals ("Entenda a disciplina da pilha."
             "Implemente o despacho de bytecode com CASE."
             "Use a VM como oraculo de corretude enquanto o compilador cresce.")
     :sections
     ((:heading "O loop da VM"
       :paragraphs ("A VM mantem um contador de programa, uma pilha, uma lista de saida e um ambiente. Cada instrucao de bytecode manipula esses valores ou altera o contador de programa."))
      (:heading "Execute antes de otimizar"
       :paragraphs ("Interpretadores sao excelentes fixtures de teste. Antes de adicionar saida nativa, faca a execucao do bytecode ficar previsivel e sem surpresas."))))
    (:title "Construtos de Controle"
     :deck "Use rotulos e saltos para implementar IF e WHILE."
     :goals ("Compile fluxo de controle estruturado sem perder estrutura no parser."
             "Monte rotulos simbolicos em alvos numericos de salto."
             "Mantenha a analise de comandos separada da analise de expressoes.")
     :sections
     ((:heading "Rotulos primeiro, enderecos depois"
       :paragraphs ("O compilador emite rotulos simbolicos porque eles sao faceis para humanos e faceis de ajustar. Um pequeno passe montador remove marcadores de rotulo e reescreve saltos para indices de instrucao."))
      (:heading "Um exemplo de loop"
       :paragraphs ("O corpo do loop e apenas outro bloco de comandos. Isso permite loops e condicionais aninhados usando o mesmo parser."))))
    (:title "Expressoes Booleanas"
     :deck "Mantenha booleanos simples ate a linguagem precisar de semantica mais rica."
     :goals ("Compile operadores relacionais como expressoes que produzem inteiros."
             "Veja como truthiness guia saltos condicionais."
             "Planeje AND e OR com curto-circuito como refinamento posterior.")
     :sections
     ((:heading "Zero e nao zero"
       :paragraphs ("A VM Tiny trata zero como falso e qualquer inteiro diferente de zero como verdadeiro. Isso basta para if e while e mantem o bytecode compacto."))
      (:heading "Onde AND e OR pertencem"
       :paragraphs ("AND e OR podem ser operadores comuns, mas curto-circuito real e fluxo de controle. Um parser posterior pode adicionar precedencia booleana e compilar AND como um salto antecipado quando o lado esquerdo for falso."))))
    (:title "Analise Lexica"
     :deck "Entregue tokens ao parser em vez de caracteres crus."
     :goals ("Escaneie inteiros, identificadores, palavras-chave, simbolos e comentarios."
             "Anexe posicoes aos tokens para erros melhores."
             "Mantenha o texto dos tokens normalizado.")
     :sections
     ((:heading "Um token e um pequeno registro"
       :paragraphs ("O scanner e a primeira fronteira do compilador. Ele oculta espacos e comentarios enquanto preserva informacao de posicao suficiente para explicar erros."))
      (:heading "Palavras-chave sao nomes com uma tabela"
       :paragraphs ("O scanner le uma palavra uma vez, normaliza para minusculas e decide se ela e palavra-chave ou identificador. O parser pode entao pedir a palavra-chave LET sem se importar com quantos espacos havia no codigo fonte."))))
    (:title "Um Pouco de Filosofia"
     :deck "Prefira um compilador que voce consegue explicar a um que apenas parece impressionante."
     :goals ("Preserve passes pequenos."
             "Use nomes que revelem a gramatica."
             "Adie abstracoes ate que um segundo exemplo as peca.")
     :sections
     ((:heading "A quantidade certa de esperteza"
       :paragraphs ("Common Lisp torna tentador escrever imediatamente um gerador de parser. Neste curso, o parser escrito a mao e a licao: ele mostra onde precedencia, comandos e blocos realmente vivem."))
      (:heading "Use o REPL"
       :paragraphs ("Quando uma stream de tokens parecer errada, inspecione-a diretamente. Quando uma AST parecer errada, compile apenas aquela parte. O REPL nao e ferramenta secundaria; ele faz parte do ciclo de construcao do compilador."))))
    (:title "Uma Visao de Cima"
     :deck "Conecte o pipeline do compilador do texto fonte ate a saida."
     :goals ("Rastreie o caminho completo por scanner, parser, compilador, montador e VM."
             "Identifique o que cada passe consome e retorna."
             "Mantenha contratos de passe explicitos.")
     :sections
     ((:heading "O pipeline"
       :paragraphs ("Cada passe do compilador deve aceitar um tipo de valor e retornar outro. Isso torna o sistema testavel sem exigir uma execucao completa de ponta a ponta a cada mudanca."))
      (:heading "Uma funcao publica"
       :paragraphs ("Uma funcao conveniente de topo ainda deve chamar os passes menores. Nao esconda as funcoes de passe; elas sao como voce aprende e depura."))))
    (:title "Apresentando Tiny"
     :deck "Defina a pequena linguagem de ensino usada pelo restante do site."
     :goals ("Documente a sintaxe suportada pela implementacao."
             "Mantenha a primeira linguagem apenas com inteiros."
             "Faca cada recurso justificar seu custo de implementacao.")
     :sections
     ((:heading "Sintaxe de Tiny"
       :paragraphs ("Tiny tem aritmetica inteira, variaveis, comandos print, if/else e loops while. Os comandos sao deliberadamente enxutos para que o compilador continue visivel."))
      (:heading "Um programa Tiny completo"
       :paragraphs ("Este programa calcula um fatorial usando apenas os construtos ja implementados pelo parser e pela VM."))))
    (:title "Analise Lexica Revisitada"
     :deck "Melhore diagnosticos e torne o tratamento de tokens mais estrito."
     :goals ("Reporte posicoes de caracteres."
             "Rejeite entrada desconhecida cedo."
             "Normalize escolhas de fonte antes que elas cheguem ao parser.")
     :sections
     ((:heading "Posicoes de erro"
       :paragraphs ("Um compilador que falha alto, mas de modo vago, e dificil de usar. Posicoes de token permitem que erros de sintaxe apontem para o caractere de origem que causou o problema."))
      (:heading "Comentarios"
       :paragraphs ("Comentarios sao trabalho do scanner, nao do parser. O scanner de Tiny trata # como comentario de linha e descarta o resto da linha."))))
    (:title "Miscelanea"
     :deck "Ajuste as bordas: divisao, padroes e listagens geradas."
     :goals ("Decida a semantica da divisao inteira."
             "Escolha o comportamento para leitura de variaveis nao inicializadas."
             "Gere listagens de fonte a partir do arquivo real do compilador.")
     :sections
     ((:heading "Divisao inteira"
       :paragraphs ("A VM usa TRUNCATE de Common Lisp para divisao inteira. Isso e explicito, portavel e facil de substituir se a linguagem depois quiser divisao racional ou por piso."))
      (:heading "Variaveis nao inicializadas"
       :paragraphs ("A primeira VM retorna zero para uma variavel ausente. Isso espelha muitas linguagens pequenas de ensino, mas o parser e o compilador estao estruturados para que um passe de tabela de simbolos possa rejeitar o mesmo programa depois."))))
    (:title "Procedimentos"
     :deck "Planeje chamadas, parametros e ambientes locais."
     :goals ("Separe analisar um procedimento de invoca-lo."
             "Veja por que frames de chamada pertencem a VM."
             "Esboce uma extensao futura sem complicar o codigo atual.")
     :sections
     ((:heading "Esboco de sintaxe para procedimentos"
       :paragraphs ("Procedimentos adicionam dois conceitos: um bloco nomeado e uma instrucao de chamada. O parser pode coletar definicoes no topo enquanto comandos dentro de um bloco podem chama-las."))
      (:heading "Frames de chamada"
       :paragraphs ("Uma chamada real de procedimento precisa de endereco de retorno e ambiente local. Isso pertence a VM, nao a um truque no parser."))))
    (:title "Tipos"
     :deck "Adicione um pequeno passe de tipos antes da geracao de codigo."
     :goals ("Diferencie sintaxe de significado."
             "Use um passe separado para anotar ou rejeitar programas."
             "Mantenha o primeiro sistema de tipos pequeno.")
     :sections
     ((:heading "Um ambiente de tipos"
       :paragraphs ("O parser deve aceitar sintaxe, nao decidir toda regra semantica. Um passe de tipos pode caminhar pela AST com uma tabela de nomes de variaveis e tipos esperados."))
      (:heading "Primeiras checagens uteis"
       :paragraphs ("Comece rejeitando variaveis desconhecidas e condicoes nao inteiras se voce adicionar booleanos verdadeiros depois. Faca isso antes da geracao de bytecode para o compilador falhar antes de emitir codigo parcial."))))
    (:title "De Volta ao Futuro"
     :deck "Para onde este compilador simples pode ir depois."
     :goals ("Troque o backend da VM por outro alvo."
             "Mantenha estavel o contrato da AST."
             "Use testes para proteger refatoracoes.")
     :sections
     ((:heading "Trocas de backend"
       :paragraphs ("Quando a AST estiver estavel, o backend de bytecode e apenas um alvo possivel. Voce pode emitir C, texto WebAssembly, assembly nativo ou forms de Common Lisp a partir da mesma arvore."))
      (:heading "Mantenha exemplos executaveis"
       :paragraphs ("Tutoriais de compiladores envelhecem melhor quando seus exemplos sao executaveis. Os exemplos deste site sao cobertos por um arquivo de testes que exercita scanner, parser, bytecode e paginas geradas."))))
    (:title "Construcao de Unidades"
     :deck "Empacote o compilador como um conjunto de unidades claras em Common Lisp."
     :goals ("Use pacotes como fronteiras de modulo."
             "Exporte apenas a API de ensino."
             "Construa o site a partir de dados Lisp.")
     :sections
	     ((:heading "Pacotes fazem parte do design"
	       :paragraphs ("O projeto separa compilador, conteudo do curso, renderer e testes em pacotes. Isso impede que o gerador do site dependa de detalhes internos do parser que ele nao precisa."))
	      (:heading "O site e dados Lisp"
	       :paragraphs ("Licoes sao estruturas, exemplos de codigo sao strings e o renderer transforma tudo em HTML. Isso satisfaz a restricao central: a fonte mantida para o site e para os exemplos e Common Lisp."))))
    (:title "Bootstrap do Pacote"
     :deck "Faca o arquivo fonte do compilador conseguir definir o proprio pacote quando for executado sozinho."
     :goals ("Entenda por que IN-PACKAGE precisa que o pacote exista antes do restante do arquivo carregar."
             "Use EVAL-WHEN para executar codigo de preparacao em tempo de compilacao, carregamento e execucao direta."
             "Proteja DEFPACKAGE para que o uso como script standalone e o carregamento normal do sistema funcionem.")
     :sections
     ((:heading "Por que este form vem primeiro"
       :paragraphs ("O arquivo do compilador comeca com um form IN-PACKAGE. Esse form so funciona se o pacote LBCCL.COMPILER ja existir."
                    "Quando o site carrega o projeto inteiro, src/package.lisp cria esse pacote primeiro. Quando alguem executa apenas src/tiny-compiler.lisp, o proprio arquivo do compilador precisa criar o pacote antes que IN-PACKAGE seja lido."))
      (:heading "O que EVAL-WHEN muda"
       :paragraphs ("EVAL-WHEN controla quando um form de topo e avaliado. O caso :compile-toplevel importa se o arquivo for compilado, porque os forms posteriores precisam do pacote enquanto o compilador esta lendo e compilando."
                    "O caso :load-toplevel importa quando um arquivo fonte ou compilado e carregado. O caso :execute importa quando o form e avaliado diretamente, inclusive em carregamento no estilo script."))
      (:heading "A guarda e a API publica"
       :paragraphs ("FIND-PACKAGE e chamado com a string \"LBCCL.COMPILER\" para que a busca independa do pacote atual. Se o pacote ja existe, UNLESS pula DEFPACKAGE e evita redefini-lo."
                    "DEFPACKAGE diz que o pacote do compilador usa CL e exporta a API de ensino. A sintaxe #: cria simbolos nao internados para os nomes na definicao do pacote, evitando internamento acidental no pacote que le este form."))))))

(defun translated-section (base-section translation)
  (make-section :heading (getf translation :heading)
                :paragraphs (getf translation :paragraphs)
                :code (section-code base-section)
                :notes (getf translation :notes)))

(defun translated-lesson (base-lesson translation)
  (let ((section-translations (getf translation :sections))
        (base-sections (lesson-sections base-lesson)))
    (unless (= (length base-sections) (length section-translations))
      (error "Translation section count mismatch for lesson ~D"
             (lesson-number base-lesson)))
    (make-lesson :number (lesson-number base-lesson)
                 :slug (lesson-slug base-lesson)
                 :title (getf translation :title)
                 :deck (getf translation :deck)
                 :goals (getf translation :goals)
                 :sections (loop for base-section in base-sections
                                 for section-translation in section-translations
                                 collect (translated-section base-section
                                                            section-translation)))))

(defun translated-lessons (translations)
  (unless (= (length *lessons*) (length translations))
    (error "Translation lesson count mismatch."))
  (loop for base-lesson in *lessons*
        for translation in translations
        collect (translated-lesson base-lesson translation)))

(defparameter *lessons-pt-br*
  (translated-lessons *pt-br-lesson-translations*))

(defun course-title-for-language (language)
  (ecase language
    (:en *course-title*)
    (:pt-br *course-title-pt-br*)))

(defun course-deck-for-language (language)
  (ecase language
    (:en *course-deck*)
    (:pt-br *course-deck-pt-br*)))

(defun lessons-for-language (language)
  (ecase language
    (:en *lessons*)
    (:pt-br *lessons-pt-br*)))
