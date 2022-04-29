# Project-Petri
a project with petri nets in godot

O programa abre no seu menu principal - a simulação.
Esta encontra-se inicialmente parada e deserta de agentes.
Para adicionar agentes, selecionamos um da lista clicando no seu nome, e de seguida clicamos nas celulas da simulação em que o queremos colocar.
Selecionar um dos agentes faz-nos esntrar em "modo edição" (o icon de lupa no topo é substituido por um de edição para indicar isto)
Enquanto no "modo de edição", se clicarmos numa celula da simulação com o botão direito do rato removeremos os agentes que lá se encontram.

Ao clicar no icon de edição, este é substituido por o de uma lupa, indicando que estamos agora no "modo de investigação".
Clicar nas celulas no "modo de investigação" apresenta-nos informação sobre estas, incluindo quantos tokens se encontram publicamente disponiveis nelas (sobre isto mais à frente) e uma lista dos agentes que lá se encontram.

Clicar no icon de pausa ao lado do icon de lupa/edição faz-nos entrar em "modo play", em que a simulação avança automaticamente.
Investigar uma celula, ou selecionar um dos agentes da lista à direita para adicionar à simulação remove-nos do "modo play".
Fora do "modo play" podemos em qualquer momento carregar no espaço para avançar a simulação uma iteração.

O último icon dos 3 no topo é o de "clean", que recomeça a simulação do 0, sem agentes na grelha.

A lista de agentes à direita apresenta no seu topo um botão de adicionar novo agente. Clicar neste, ou no botão de editar ao lado do nome de cada agente na lista, ou no nome de um agente em particular quando investigamos uma celula especifica leva-nos ao menu de edição do agente.

No menu de edição do agente temos à nossa disponibilidade ferramentas para editar a estrutura da petri net que dita as suas ações, bem como o seu nome e cor. Editar o nome de um agente irá criar um novo tipo de agente. Editar um agente sem lhe mudar o nome irá substituir o seu "save" anterior.

Detalhes mais especificos sobre a edição das petri nets:
  - Transições podem ou não ter ações associadas que são realizadas sempre que a transição é disparada. Estas ações podem levar argumentos. A ação de adicionar novos agentes requere que no argumento esteja o nome exato do tipo de agente a adicionar - este irá ser colocado na mesma posição na grelha que o agente que o cria. Ações de movimento levam como argumento as celulas percorridas num movimento. A ação de "morrer" não requere argumentos.
  - Posições podem ser:
    - Privadas; Os tokens nestas podem ser diretamente editados neste menu;
    - Publicas; Onde é requerido inserir as coordenadas relativas ao agente desta posição publica. O número de tokens nestas posições pode ser editado quando investigamos a celula onde se encontram no "modo de investigação" no menu de simulação.
    - Shared Places; Onde requerem o nome usado como chave para aceder a este shared place. Os shared places podem ser visionados em tempo real no lado direito do menu de simulação, por baixo da lista de agentes, e o seu numero de tokens pode ser lá editado.
