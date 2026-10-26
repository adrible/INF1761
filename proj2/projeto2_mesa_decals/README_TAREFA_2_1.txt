INF1761 - Computacao Grafica
Tarefa 2.1 - Cena 3D simples

ARQUIVO PRINCIPAL
  python/main_3d.py

REQUISITOS
  Python 3.11+
  wgpu
  rendercanvas
  glfw
  numpy

INSTALACAO (Windows)
  py -m pip install -r requirements.txt

EXECUCAO
  A partir da pasta tarefa2_1_scene_graph:

    py python/main_3d.py

  Tambem e possivel abrir python/main_3d.py no Spyder e executar.

CONTROLES
  - Clique e arraste com o mouse: manipula a camera pelo arcball.
  - Tecla Q: fecha a janela.

O QUE FOI ALTERADO EM RELACAO AO CODIGO-BASE
  - main_3d.py foi adaptado para criar a cena pedida na Tarefa 2.1.
  - Foram mantidas as classes fornecidas pelo professor para grafo de cena,
    camera, arcball, pipeline, materiais, cubo, esfera e iluminacao.
  - O shader utilizado continua sendo shaders/ilum_frag/lit.wgsl, que calcula
    a iluminacao por fragmento.
  - Foi usada uma PointLight e materiais Phong.

COMPOSICAO DA CENA
  - 1 cubo achatado: tampo da mesa
  - 4 cubos alongados: pernas da mesa
  - 1 cubo amarelo sobre o tampo
  - 1 esfera verde sobre o cubo amarelo
  - 1 esfera vermelha maior sobre o tampo

ENTREGA
  O enunciado pede um relatorio PDF sucinto e um link para um video mostrando
  a manipulacao da camera com o mouse.
