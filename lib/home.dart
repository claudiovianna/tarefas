import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

class Home extends StatefulWidget {
  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {

  //atributos
  List _toDoList = [];

  //variáveis importantes para deletar itens
  Map<String, dynamic> _lastRemoved;
  int _lastRemovedPos;

  //necessário para a recuperação e carregamento da lista existente na tela
  @override
  void initState() {
    super.initState();
    _readData().then((data) {
      setState(() {
        _toDoList = json.decode(data);
      });

    });
  }

  //controladores
  final _novaTarefaController = TextEditingController();

  //métodos
  //método que adiciona tarefa na lista
  void _addToDo(){
    //Map<String,dynamic> newToDo
    setState(() {
      Map<String, dynamic> newToDo = Map();
      newToDo["title"] = _novaTarefaController.text;
      _novaTarefaController.text = "";
      newToDo["ok"] = false;
      _toDoList.add(newToDo);

      _saveData();
    });
  }
  //método que retorna o arquivo json que salva meus dados
  Future<File> _getFile() async{
    //cada sistema operacional armazena em locais diferentes
    //para isso é necessário saber onde pode ser armazenado
    // dados para sua aplicação
    final diretorio = await getApplicationDocumentsDirectory();
    return File("${diretorio.path}/taresfas.json");
  }
  //método para salvar os dados
  Future<File> _saveData() async {
    //transformando a lista em json
    String data = json.encode(_toDoList);
    //recuperando o arquivo existente
    final file = await _getFile();
    //escrevendo a lista em formato String (json) no arquivo de dados e retorná-lo
    return file.writeAsString(data);
  }
  //método para obter os dados
  Future<String> _readData() async {
    //é necessário tratar erro caso haja, usando try / catch
    try {
      final file = await _getFile();
      return file.readAsStringSync();
    } catch (e){
      return null;
    }
  }
  //método para recarregar e ordenar por não marcadas e marcadas
  //a lista na tela com um pequeno delay
  Future<Null> _refresh() async{
    await Future.delayed(Duration(seconds: 1));

    setState(() {
      _toDoList.sort((a, b) {
        if(a["ok"] && !b["ok"]){
          return 1;
        }else if(!a["ok"] && b["ok"]){
          return -1;
        }else {
          return 0;
        }
      });

      _saveData();
    });

    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Tarefas"),
        backgroundColor: Colors.green,
        centerTitle: true,
      ),
      body: Column(
        children: <Widget>[
          Container(
            padding: EdgeInsets.fromLTRB(17, 1, 7, 1),
            child: Row(
              children: <Widget>[
                ///é necessário usar o Expanded pq ele não sabe
                ///o quanto de espaço o TextField pode ocupar na tela.
                ///usando o Expanded o TextField irá se expandor até o RaisedButton
                Expanded(
                  child: TextFormField(
                    controller: _novaTarefaController,
                    decoration: InputDecoration(
                      labelText: "Nova Tarefa",
                      labelStyle: TextStyle(
                        color: Colors.green
                      )
                    ),
                  ),
                ),
                RaisedButton(
                  color: Colors.green,
                  child: Text("ADD"),
                  textColor: Colors.white,
                  onPressed: _addToDo,
                )
              ],
            ),
          ),
          Expanded(
            ///utilizamos ListVuew.builder para economizar recurso
            ///deste jeito só os dados visíveis serão carregados
            child: RefreshIndicator(
              child: ListView.builder(
                  padding: EdgeInsets.only(top: 10),
                  //o uso das "?" e "??" é para garantir uma quantidade e itens
                  // caso não exita a lista
                  itemCount: _toDoList?.length ?? 0,
                  ///para construir a lista é preciso passar um context e um index
                  itemBuilder: buildItem),
                onRefresh: _refresh,
            )
          )
        ],
      ),
    );
  }

  Widget buildItem(BuildContext context, int index) {
    return Dismissible(
      //essa key vai definir qual item será deletado
      key: Key(
        DateTime.now().millisecondsSinceEpoch.toString()
      ),
      background: Container(
        color: Colors.red,
        child: Align(
          //no Alignment o x vai de -1 a 1 e y vai de -1 a 1
          alignment: Alignment(-0.9 , 0),
          child: Icon(
            Icons.delete,
            color: Colors.white,
          ),
        ),
      ),
      direction: DismissDirection.startToEnd,
      child:   CheckboxListTile(
        title: Text(_toDoList[index]["title"]),
        value: _toDoList[index]["ok"],
        secondary: CircleAvatar(
          child: Icon(_toDoList[index]["ok"] ? Icons.check : Icons.error),
        ),
        onChanged: (c) {
          setState(() {
            _toDoList[index]["ok"] = c;

            _saveData();
          });
        },
      ),
      onDismissed: (direction) {
        setState(() {
          //duplicando o mapa do item removido
          _lastRemoved = Map.from(_toDoList[index]);
          //salvando a posição que estamos removendo
          _lastRemovedPos = index;
          //revomendo o item da posição determinada
          _toDoList.removeAt(index);
          //salvar a lista com o item já removido
          _saveData();

          final snack = SnackBar(
            content: Text("Tarefa \"${_lastRemoved["title"]}\" removida"),
            action: SnackBarAction(
              label: "Desfazer",
              onPressed: () {
                setState(() {
                  _toDoList.insert(_lastRemovedPos, _lastRemoved);
                  _saveData();
                });
              },
            ),
            duration: Duration(seconds: 4),
          );

          //removendo snackBar atual
          Scaffold.of(context).removeCurrentSnackBar();
          //mostrando o snackBar
          Scaffold.of(context).showSnackBar(snack);
        });
      },
    );
  }
//adiciona e salva um novo item
//  CheckboxListTile(
//  title: Text(_toDoList[index]["title"]),
//  value: _toDoList[index]["ok"],
//  secondary: CircleAvatar(
//  child: Icon(_toDoList[index]["ok"] ? Icons.check : Icons.error),
//  ),
//  onChanged: (c) {
//  setState(() {
//  _toDoList[index]["ok"] = c;
//
//  _saveData();
//  });
//  },
//  );
}
