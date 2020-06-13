part of smashlibs;
/*
 * Copyright (c) 2019-2020. Antonello Andrea (www.hydrologis.com). All rights reserved.
 * Use of this source code is governed by a GPL3 license that can be
 * found in the LICENSE file.
 */

typedef Null ItemSelectedCallback(String selectedFormName);

class FormSectionsWidget extends StatefulWidget {
  final ItemSelectedCallback onItemSelected;
  final String sectionName;
  final bool isLargeScreen;
  final Map<String, dynamic> sectionMap;

  FormSectionsWidget(this.sectionMap, this.sectionName, this.isLargeScreen,
      this.onItemSelected);

  @override
  State<StatefulWidget> createState() {
    return FormSectionsWidgetState();
  }
}

class FormSectionsWidgetState extends State<FormSectionsWidget> {
  int _selectedPosition = 0;

  @override
  Widget build(BuildContext context) {
    var formNames4Section = TagsManager.getFormNames4Section(widget.sectionMap);

    return ListView.builder(
      itemCount: formNames4Section.length,
      itemBuilder: (context, position) {
        return Ink(
          color: _selectedPosition == position && widget.isLargeScreen
              ? SmashColors.mainDecorationsMc[50]
              : null,
          child: ListTile(
            onTap: () {
              widget.onItemSelected(formNames4Section[position]);
              setState(() {
                _selectedPosition = position;
              });
            },
            title: SmashUI.normalText(formNames4Section[position],
                bold: true, color: SmashColors.mainDecorationsDarker),
          ),
        );
      },
    );
  }
}

class FormDetailWidget extends StatefulWidget {
  final String sectionName;
  final String formName;
  final bool isLargeScreen;
  final bool onlyDetail;
  final dynamic _position;
  final int _noteId;
  final Map<String, dynamic> sectionMap;
  final AFormhelper formHelper;
  final bool doScaffold;
  final bool isReadOnly;

  FormDetailWidget(
    this._noteId,
    this.sectionMap,
    this.sectionName,
    this.formName,
    this.isLargeScreen,
    this.onlyDetail,
    this._position,
    this.formHelper, {
    this.isReadOnly = false,
    this.doScaffold = true,
  });

  @override
  State<StatefulWidget> createState() {
    return FormDetailWidgetState();
  }
}

class FormDetailWidgetState extends State<FormDetailWidget> {
  List<String> formNames;

  @override
  void initState() {
    formNames = TagsManager.getFormNames4Section(widget.sectionMap);

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    List<ListTile> widgetsList = [];
    var formName = widget.formName;
    if (formName == null) {
      // pick the first of the section
      formName = formNames[0];
    }
    var form4name = TagsManager.getForm4Name(formName, widget.sectionMap);
    List<dynamic> formItems = TagsManager.getFormItems(form4name);

    for (int i = 0; i < formItems.length; i++) {
      Widget w = getWidget(context, widget._noteId, formItems[i],
          widget._position, widget.isReadOnly, widget.formHelper);
      if (w != null) {
        widgetsList.add(w);
      }
    }

    var bodyContainer = Container(
      color: widget.isLargeScreen && !widget.onlyDetail
          ? SmashColors.mainDecorationsMc[50]
          : null,
      child: ListView.builder(
        itemCount: widgetsList.length,
        itemBuilder: (context, index) {
          return Container(
            padding: EdgeInsets.only(top: 10.0),
            child: widgetsList[index],
          );
        },
        padding: EdgeInsets.only(bottom: 10.0),
      ),
    );
    return widget.doScaffold
        ? Scaffold(
            appBar: !widget.isLargeScreen && !widget.onlyDetail
                ? AppBar(
                    title: Text(formName),
                  )
                : null,
            body: bodyContainer,
          )
        : bodyContainer;
  }
}

class MasterDetailPage extends StatefulWidget {
  final Widget title;
  final String sectionName;
  final dynamic _position;
  final int _noteId;
  final Map<String, dynamic> sectionMap;
  final AFormhelper formHelper;
  final bool doScaffold;
  final bool isReadOnly;

  MasterDetailPage(
    this.sectionMap,
    this.title,
    this.sectionName,
    this._position,
    this._noteId,
    this.formHelper, {
    this.doScaffold = true,
    this.isReadOnly = false,
  });

  @override
  _MasterDetailPageState createState() => _MasterDetailPageState();
}

class _MasterDetailPageState extends State<MasterDetailPage> {
  String selectedForm;
  var isLargeScreen = false;

  @override
  Widget build(BuildContext context) {
    var formNames = TagsManager.getFormNames4Section(widget.sectionMap);

    // in case of single tab, display detail directly
    bool onlyDetail = formNames.length == 1;

    var bodyContainer = OrientationBuilder(builder: (context, orientation) {
      isLargeScreen = ScreenUtilities.isLargeScreen(context);

      return Row(children: <Widget>[
        !onlyDetail
            ? Expanded(
                flex: isLargeScreen ? 4 : 1,
                child: FormSectionsWidget(
                    widget.sectionMap, widget.sectionName, isLargeScreen,
                    (formName) {
                  if (isLargeScreen) {
                    selectedForm = formName;
                    setState(() {});
                  } else {
                    Navigator.push(context, MaterialPageRoute(
                      builder: (context) {
                        return FormDetailWidget(
                          widget._noteId,
                          widget.sectionMap,
                          widget.sectionName,
                          formName,
                          isLargeScreen,
                          onlyDetail,
                          widget._position,
                          widget.formHelper,
                          doScaffold: widget.doScaffold,
                          isReadOnly: widget.isReadOnly,
                        );
                      },
                    ));
                  }
                }),
              )
            : Container(),
        isLargeScreen || onlyDetail
            ? Expanded(
                flex: 6,
                child: FormDetailWidget(
                  widget._noteId,
                  widget.sectionMap,
                  widget.sectionName,
                  selectedForm,
                  isLargeScreen,
                  onlyDetail,
                  widget._position,
                  widget.formHelper,
                  doScaffold: widget.doScaffold,
                  isReadOnly: widget.isReadOnly,
                ))
            : Container(),
      ]);
    });
    return WillPopScope(
      onWillPop: () async {
        // TODO check if something cheanged would be really good
        await widget.formHelper.onSaveFunction(context, widget._noteId,
            widget.sectionName, widget.sectionMap, widget._position);
        return true;
      },
      child: widget.doScaffold
          ? Scaffold(
              appBar: AppBar(
                title: widget.title,
              ),
              body: bodyContainer,
            )
          : bodyContainer,
    );
  }
}

ListTile getWidget(
  BuildContext context,
  int noteId,
  final Map<String, dynamic> itemMap,
  dynamic position,
  bool isReadOnly,
  AFormhelper formHelper,
) {
  String key = "-"; //$NON-NLS-1$
  if (itemMap.containsKey(TAG_KEY)) {
    key = itemMap[TAG_KEY].trim();
  }
  String label = TagsManager.getLabelFromFormItem(itemMap);

  dynamic value = ""; //$NON-NLS-1$
  if (itemMap.containsKey(TAG_VALUE)) {
    value = itemMap[TAG_VALUE].trim();
  }
  String type = TYPE_STRING;
  if (itemMap.containsKey(TAG_TYPE)) {
    type = itemMap[TAG_TYPE].trim();
  }
  String iconStr;
  if (itemMap.containsKey(TAG_ICON)) {
    iconStr = itemMap[TAG_ICON].trim();
  }

  Icon icon;
  if (iconStr != null) {
    var iconData = getSmashIcon(iconStr);
    icon = Icon(
      iconData,
      color: SmashColors.mainDecorations,
    );
  }

  bool itemReadonly = false;
  if (itemMap.containsKey(TAG_READONLY)) {
    var readonlyObj = itemMap[TAG_READONLY].trim();
    if (readonlyObj is String) {
      itemReadonly = readonlyObj == 'true';
    } else if (readonlyObj is bool) {
      itemReadonly = readonlyObj;
    } else if (readonlyObj is num) {
      itemReadonly = readonlyObj.toDouble() == 1.0;
    }
  }

  if (isReadOnly) {
    // global readonly overrides the item one
    itemReadonly = true;
  }

  Constraints constraints = new Constraints();
  FormUtilities.handleConstraints(itemMap, constraints);
//    key2ConstraintsMap.put(key, constraints);
//    String constraintDescription = constraints.getDescription();

  var minLines = 1;
  var maxLines = 1;
  var keyboardType = TextInputType.text;
  var textDecoration = TextDecoration.none;
  switch (type) {
    case TYPE_STRINGAREA:
      {
        minLines = 5;
        maxLines = 5;
        continue TYPE_STRING;
      }
    case TYPE_DOUBLE:
      {
        keyboardType =
            TextInputType.numberWithOptions(signed: true, decimal: true);
        continue TYPE_STRING;
      }
    case TYPE_INTEGER:
      {
        keyboardType =
            TextInputType.numberWithOptions(signed: true, decimal: false);
        continue TYPE_STRING;
      }
    TYPE_STRING:
    case TYPE_STRING:
      {
        TextEditingController stringController =
            new TextEditingController(text: value);

        stringController.addListener(() {
          itemMap[TAG_VALUE] = stringController.text;
        });
        TextFormField field = TextFormField(
          validator: (value) {
            if (!constraints.isValid(value)) {
              return constraints.getDescription();
            }
            return null;
          },
          autovalidate: true,
          decoration: InputDecoration(
//            icon: icon,
            labelText: "$label ${constraints.getDescription()}",
          ),
          controller: stringController,
          enabled: !itemReadonly,
          minLines: minLines,
          maxLines: maxLines,
          keyboardType: keyboardType,
        );

        ListTile tile = ListTile(
          title: field,
          leading: icon,
        );
        return tile;
      }
    case TYPE_LABELWITHLINE:
      {
        textDecoration = TextDecoration.underline;
        continue TYPE_LABEL;
      }
    TYPE_LABEL:
    case TYPE_LABEL:
      {
        String sizeStr = "20";
        if (itemMap.containsKey(TAG_SIZE)) {
          sizeStr = itemMap[TAG_SIZE];
        }
        double size = double.parse(sizeStr);
        String url;
        if (itemMap.containsKey(TAG_URL)) {
          url = itemMap[TAG_URL];
          textDecoration = TextDecoration.underline;
        }

        var text = Text(
          value.toString(),
          style: TextStyle(
              fontSize: size,
              decoration: textDecoration,
              color: SmashColors.mainDecorationsDarker),
          textAlign: TextAlign.start,
        );

        ListTile tile;
        if (url == null) {
          tile = ListTile(
            leading: icon,
            title: text,
          );
        } else {
          tile = ListTile(
            leading: icon,
            title: GestureDetector(
              onTap: () async {
                if (await canLaunch(url)) {
                  await launch(url);
                } else {
                  showErrorDialog(context, "Unable to open url: $url");
                }
              },
              child: text,
            ),
          );
        }
        return tile;
      }
    case TYPE_DYNAMICSTRING:
      {
        return ListTile(
          leading: icon,
          title: DynamicStringWidget(itemMap, label, itemReadonly),
        );
      }
    case TYPE_DATE:
      {
        return ListTile(
          leading: icon,
          title: DatePickerWidget(itemMap, label, itemReadonly),
        );
      }
    case TYPE_TIME:
      {
        return ListTile(
          leading: icon,
          title: TimePickerWidget(itemMap, label, itemReadonly),
        );
      }
    case TYPE_BOOLEAN:
      {
        return ListTile(
          leading: icon,
          title: CheckboxWidget(itemMap, label, itemReadonly),
        );
      }
    case TYPE_STRINGCOMBO:
      {
        return ListTile(
          leading: icon,
          title: ComboboxWidget(itemMap, label, itemReadonly),
        );
      }
    // case TYPE_AUTOCOMPLETESTRINGCOMBO:
    // {
//        JSONArray comboItems = TagsManager.getComboItems(jsonObject);
//        String[] itemsArray = TagsManager.comboItems2StringArray(comboItems);
//        addedView = FormUtilities.addAutocompleteComboView(activity, mainView, label, value, itemsArray, constraintDescription);
//        break;
    // }
    case TYPE_CONNECTEDSTRINGCOMBO:
      {
        return ListTile(
          leading: icon,
          title: ConnectedComboboxWidget(itemMap, label, itemReadonly),
        );
//        LinkedHashMap<String, List<String>> valuesMap = TagsManager.extractComboValuesMap(jsonObject);
//        addedView = FormUtilities.addConnectedComboView(activity, mainView, label, value, valuesMap,
//            constraintDescription);
//        break;
      }
//      case TYPE_AUTOCOMPLETECONNECTEDSTRINGCOMBO: {
//        LinkedHashMap<String, List<String>> valuesMap = TagsManager.extractComboValuesMap(jsonObject);
//        addedView = FormUtilities.addAutoCompleteConnectedComboView(activity, mainView, label, value, valuesMap,
//            constraintDescription);
//        break;
//      }
//      case TYPE_ONETOMANYSTRINGCOMBO:
//        LinkedHashMap<String, List<NamedList<String>>> oneToManyValuesMap = TagsManager.extractOneToManyComboValuesMap(jsonObject);
//        addedView = FormUtilities.addOneToManyConnectedComboView(activity, mainView, label, value, oneToManyValuesMap,
//            constraintDescription);
//        break;
//      case TYPE_STRINGMULTIPLECHOICE: {
//        JSONArray comboItems = TagsManager.getComboItems(jsonObject);
//        String[] itemsArray = TagsManager.comboItems2StringArray(comboItems);
//        addedView = FormUtilities.addMultiSelectionView(activity, mainView, label, value, itemsArray,
//            constraintDescription);
//        break;
//      }
    case TYPE_PICTURES:
      {
        return ListTile(
          leading: icon,
          title: PicturesWidget(
              noteId, itemMap, label, position, formHelper, itemReadonly),
        );
      }
    case TYPE_IMAGELIB:
      {
        return ListTile(
          leading: icon,
          title: PicturesWidget(
              noteId, itemMap, label, position, formHelper, itemReadonly,
              fromGallery: true),
        );
      }
//      case TYPE_SKETCH:
//        addedView = FormUtilities.addSketchView(noteId, this, requestCode, mainView, label, value, constraintDescription);
//        break;
//      case TYPE_MAP:
//        if (value.length() <= 0) {
//          // need to read image
//          File tempDir = ResourcesManager.getInstance(activity).getTempDir();
//          File tmpImage = new File(tempDir, LibraryConstants.TMPPNGIMAGENAME);
//          if (tmpImage.exists()) {
//            byte[][] imageAndThumbnailFromPath = ImageUtilities.getImageAndThumbnailFromPath(tmpImage.getAbsolutePath(), 1);
//            Date date = new Date();
//            String mapImageName = ImageUtilities.getMapImageName(date);
//
//            IImagesDbHelper imageHelper = DefaultHelperClasses.getDefaulfImageHelper();
//            long imageId = imageHelper.addImage(longitude, latitude, -1.0, -1.0, date.getTime(), mapImageName, imageAndThumbnailFromPath[0], imageAndThumbnailFromPath[1], noteId);
//            value = "" + imageId;
//          }
//        }
//        addedView = FormUtilities.addMapView(activity, mainView, label, value, constraintDescription);
//        break;
//      case TYPE_NFCUID:
//        addedView = new GNfcUidView(this, null, requestCode, mainView, label, value, constraintDescription);
//        break;
    case TYPE_HIDDEN:
      break;
    default:
      print("Type non implemented yet: $type");
      break;
  }

  return null;
}

class CheckboxWidget extends StatefulWidget {
  final _itemMap;
  final String _label;
  final bool _isReadOnly;

  CheckboxWidget(this._itemMap, this._label, this._isReadOnly);

  @override
  _CheckboxWidgetState createState() => _CheckboxWidgetState();
}

class _CheckboxWidgetState extends State<CheckboxWidget> {
  @override
  Widget build(BuildContext context) {
    dynamic value = ""; //$NON-NLS-1$
    if (widget._itemMap.containsKey(TAG_VALUE)) {
      value = widget._itemMap[TAG_VALUE].trim();
    }
    bool selected = value == 'true';

    return CheckboxListTile(
      title: SmashUI.normalText(widget._label,
          color: SmashColors.mainDecorationsDarker),
      value: selected,
      onChanged: (value) {
        if (!widget._isReadOnly) {
          setState(() {
            widget._itemMap[TAG_VALUE] = "$value";
          });
        }
      },
      controlAffinity:
          ListTileControlAffinity.trailing, //  <-- leading Checkbox
    );
  }
}

class ComboboxWidget extends StatefulWidget {
  final _itemMap;
  final String _label;
  final bool _isReadOnly;

  ComboboxWidget(this._itemMap, this._label, this._isReadOnly);

  @override
  ComboboxWidgetState createState() => ComboboxWidgetState();
}

class ComboboxWidgetState extends State<ComboboxWidget> {
  @override
  Widget build(BuildContext context) {
    String value = ""; //$NON-NLS-1$
    if (widget._itemMap.containsKey(TAG_VALUE)) {
      value = widget._itemMap[TAG_VALUE].trim();
    }

    var comboItems = TagsManager.getComboItems(widget._itemMap);
    List<String> itemsArray = TagsManager.comboItems2StringArray(comboItems);
    if (!itemsArray.contains(value)) {
      value = null;
    }
    var items = itemsArray
        .map(
          (itemName) => new DropdownMenuItem(
            value: itemName,
            child: new Text(itemName),
          ),
        )
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.only(bottom: SmashUI.DEFAULT_PADDING),
          child: SmashUI.normalText(widget._label,
              color: SmashColors.mainDecorationsDarker),
        ),
        Padding(
          padding: const EdgeInsets.only(left: SmashUI.DEFAULT_PADDING * 2),
          child: Container(
            padding: EdgeInsets.only(
                left: SmashUI.DEFAULT_PADDING, right: SmashUI.DEFAULT_PADDING),
            decoration: BoxDecoration(
              shape: BoxShape.rectangle,
              border: Border.all(
                color: SmashColors.mainDecorations,
              ),
            ),
            child: DropdownButton(
              value: value,
              isExpanded: true,
              items: items,
              onChanged: (selected) {
                if (!widget._isReadOnly) {
                  setState(() {
                    widget._itemMap[TAG_VALUE] = selected;
                  });
                }
              },
            ),
          ),
        ),
      ],
    );
  }
}

class ConnectedComboboxWidget extends StatefulWidget {
  final _itemMap;
  final String _label;
  final bool _isReadOnly;

  ConnectedComboboxWidget(this._itemMap, this._label, this._isReadOnly);

  @override
  ConnectedComboboxWidgetState createState() => ConnectedComboboxWidgetState();
}

class ConnectedComboboxWidgetState extends State<ConnectedComboboxWidget> {
  String currentMain = "";
  String currentSec = "";

  List<DropdownMenuItem<String>> mainComboItems = [];
  Map<String, List<DropdownMenuItem<String>>> secondaryCombos = {};

  @override
  void initState() {
    if (widget._itemMap.containsKey(TAG_VALUES)) {
      Map<String, dynamic> valuesObj = widget._itemMap[TAG_VALUES];

      bool hasEmpty = false;
      valuesObj.forEach((key, value) {
        if (key.trim().isEmpty) {
          hasEmpty = true;
        }
        var mainComboItem = DropdownMenuItem<String>(
          child: Text(key),
          value: key,
        );
        mainComboItems.add(mainComboItem);

        List<DropdownMenuItem<String>> sec = [];
        secondaryCombos[key] = sec;
        bool subHasEmpty = false;
        value.forEach((elem) {
          dynamic item = elem[TAG_ITEM] ?? "";
          if (item.toString().trim().isEmpty) {
            subHasEmpty = true;
          }
          var secComboItem = DropdownMenuItem<String>(
            child: Text(item.toString()),
            value: item.toString(),
          );
          sec.add(secComboItem);
        });
        if (!subHasEmpty) {
          var empty = DropdownMenuItem<String>(
            child: Text(""),
            value: "",
          );
          sec.insert(0, empty);
        }
      });

      if (!hasEmpty) {
        var empty = DropdownMenuItem<String>(
          child: Text(""),
          value: "",
        );
        mainComboItems.insert(0, empty);
      }
    }

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    var formItem = widget._itemMap;

    if (formItem.containsKey(TAG_VALUE)) {
      String value = formItem[TAG_VALUE].trim();
      var split = value.split(SEP);
      if (split.length == 2) {
        currentMain = split[0];
        currentSec = split[1];
      }
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.only(bottom: SmashUI.DEFAULT_PADDING),
          child: SmashUI.normalText(widget._label,
              color: SmashColors.mainDecorationsDarker),
        ),
        Container(
          decoration: currentMain.trim().isNotEmpty
              ? BoxDecoration(
                  shape: BoxShape.rectangle,
                  border: Border.all(
                    color: SmashColors.mainDecorations,
                  ),
                )
              : null,
          child: Padding(
            padding: const EdgeInsets.all(2.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(
                      left: SmashUI.DEFAULT_PADDING * 2,
                      bottom: SmashUI.DEFAULT_PADDING),
                  child: Container(
                    padding: EdgeInsets.only(
                        left: SmashUI.DEFAULT_PADDING,
                        right: SmashUI.DEFAULT_PADDING),
                    decoration: BoxDecoration(
                      shape: BoxShape.rectangle,
                      border: Border.all(
                        color: SmashColors.mainDecorations,
                      ),
                    ),
                    child: DropdownButton<String>(
                      value: currentMain,
                      isExpanded: true,
                      items: mainComboItems,
                      onChanged: (selected) {
                        if (!widget._isReadOnly) {
                          setState(() {
                            formItem[TAG_VALUE] = selected + SEP;
                          });
                        }
                      },
                    ),
                  ),
                ),
                currentMain.trim().isEmpty
                    ? Container()
                    : Padding(
                        padding: const EdgeInsets.only(
                          left: SmashUI.DEFAULT_PADDING * 2,
                        ),
                        child: Container(
                          padding: EdgeInsets.only(
                              left: SmashUI.DEFAULT_PADDING,
                              right: SmashUI.DEFAULT_PADDING),
                          decoration: BoxDecoration(
                            shape: BoxShape.rectangle,
                            border: Border.all(
                              color: SmashColors.mainDecorations,
                            ),
                          ),
                          child: DropdownButton<String>(
                            value: currentSec,
                            isExpanded: true,
                            items: secondaryCombos[currentMain],
                            onChanged: (selected) {
                              if (!widget._isReadOnly) {
                                setState(() {
                                  setState(() {
                                    var str = widget._itemMap[TAG_VALUE];
                                    widget._itemMap[TAG_VALUE] =
                                        str.split("#")[0] + SEP + selected;
                                  });
                                });
                              }
                            },
                          ),
                        ),
                      ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class DynamicStringWidget extends StatefulWidget {
  var _itemMap;
  final String _label;
  final bool _isReadonly;

  DynamicStringWidget(this._itemMap, this._label, this._isReadonly);

  @override
  DynamicStringWidgetState createState() => DynamicStringWidgetState();
}

class DynamicStringWidgetState extends State<DynamicStringWidget> {
  @override
  Widget build(BuildContext context) {
    String value = ""; //$NON-NLS-1$
    if (widget._itemMap.containsKey(TAG_VALUE)) {
      value = widget._itemMap[TAG_VALUE].trim();
    }
    List<String> valuesSplit = value.trim().split(";");
    valuesSplit.removeWhere((s) => s.trim().isEmpty);

    return Tags(
      textField: widget._isReadonly
          ? null
          : TagsTextField(
              width: 1000,
              hintText: "add new string",
              textStyle: TextStyle(fontSize: SmashUI.NORMAL_SIZE),
              onSubmitted: (String str) {
                valuesSplit.add(str);
                setState(() {
                  widget._itemMap[TAG_VALUE] = valuesSplit.join(";");
                });
              },
            ),
      verticalDirection: VerticalDirection.up,
      // text box before the tags
      alignment: WrapAlignment.start,
      // text box aligned left
      itemCount: valuesSplit.length,
      // required
      itemBuilder: (int index) {
        final item = valuesSplit[index];

        return ItemTags(
          key: Key(index.toString()),
          index: index,
          title: item,
          active: true,
          customData: item,
          textStyle: TextStyle(
            fontSize: SmashUI.NORMAL_SIZE,
          ),
          combine: ItemTagsCombine.withTextBefore,
          pressEnabled: true,
          image: null,
          icon: null,
          activeColor: SmashColors.mainDecorations,
          highlightColor: SmashColors.mainDecorations,
          color: SmashColors.mainDecorations,
          textActiveColor: SmashColors.mainBackground,
          textColor: SmashColors.mainBackground,
          removeButton: ItemTagsRemoveButton(
            onRemoved: () {
              if (!widget._isReadonly) {
                // Remove the item from the data source.
                setState(() {
                  valuesSplit.removeAt(index);
                  String saveValue = valuesSplit.join(";");
                  widget._itemMap[TAG_VALUE] = saveValue;
                });
              }
              return true;
            },
          ),
          onPressed: (item) {
//            var removed = valuesSplit.removeAt(index);
//            valuesSplit.insert(0, removed);
//            String saveValue = valuesSplit.join(";");
//            setState(() {
//              widget._itemMap[TAG_VALUE] = saveValue;
//            });
          },
          onLongPressed: (item) => print(item),
        );
      },
    );
  }
}

class DatePickerWidget extends StatefulWidget {
  final _itemMap;
  final String _label;
  final bool _isReadOnly;

  DatePickerWidget(this._itemMap, this._label, this._isReadOnly);

  @override
  DatePickerWidgetState createState() => DatePickerWidgetState();
}

class DatePickerWidgetState extends State<DatePickerWidget> {
  @override
  Widget build(BuildContext context) {
    String value = ""; //$NON-NLS-1$
    if (widget._itemMap.containsKey(TAG_VALUE)) {
      value = widget._itemMap[TAG_VALUE].trim();
    }
    DateTime dateTime;
    if (value.isNotEmpty) {
      try {
        dateTime = TimeUtilities.ISO8601_TS_DAY_FORMATTER.parse(value);
      } catch (e) {
        // ignor eand set to now
      }
    }
    if (dateTime == null) {
      dateTime = DateTime.now();
    }

    return Center(
      child: FlatButton(
          onPressed: () {
            if (!widget._isReadOnly) {
              DatePicker.showDatePicker(
                context,
                showTitleActions: true,
                onChanged: (date) {},
                onConfirm: (date) {
                  String day =
                      TimeUtilities.ISO8601_TS_DAY_FORMATTER.format(date);
                  setState(() {
                    widget._itemMap[TAG_VALUE] = day;
                  });
                },
                currentTime: dateTime,
              );
            }
          },
          child: Center(
            child: Padding(
              padding: SmashUI.defaultPadding(),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Padding(
                        padding: SmashUI.defaultRigthPadding(),
                        child: Icon(
                          MdiIcons.calendar,
                          color: SmashColors.mainDecorations,
                        ),
                      ),
                      SmashUI.normalText(widget._label,
                          color: SmashColors.mainDecorations, bold: true),
                    ],
                  ),
                  value.isNotEmpty
                      ? SmashUI.normalText("$value",
                          color: SmashColors.mainDecorations, bold: true)
                      : Container(),
                ],
              ),
            ),
          )),
    );
  }
}

class TimePickerWidget extends StatefulWidget {
  final _itemMap;
  final String _label;
  final bool _isReadOnly;

  TimePickerWidget(this._itemMap, this._label, this._isReadOnly);

  @override
  TimePickerWidgetState createState() => TimePickerWidgetState();
}

class TimePickerWidgetState extends State<TimePickerWidget> {
  @override
  Widget build(BuildContext context) {
    String value = ""; //$NON-NLS-1$
    if (widget._itemMap.containsKey(TAG_VALUE)) {
      value = widget._itemMap[TAG_VALUE].trim();
    }
    DateTime dateTime;
    if (value.isNotEmpty) {
      try {
        dateTime = TimeUtilities.ISO8601_TS_TIME_FORMATTER.parse(value);
      } catch (e) {
        // ignore and set to now
      }
    }
    if (dateTime == null) {
      dateTime = DateTime.now();
    }

    return Center(
      child: FlatButton(
          onPressed: () {
            if (!widget._isReadOnly) {
              DatePicker.showTimePicker(
                context,
                showTitleActions: true,
                onChanged: (date) {},
                onConfirm: (date) {
                  String time =
                      TimeUtilities.ISO8601_TS_TIME_FORMATTER.format(date);
                  setState(() {
                    widget._itemMap[TAG_VALUE] = time;
                  });
                },
                currentTime: dateTime,
              );
            }
          },
          child: Center(
            child: Padding(
              padding: SmashUI.defaultPadding(),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Padding(
                    padding: SmashUI.defaultRigthPadding(),
                    child: Icon(
                      MdiIcons.clock,
                      color: SmashColors.mainDecorations,
                    ),
                  ),
                  SmashUI.normalText(
                      value.isNotEmpty
                          ? "${widget._label}: $value"
                          : widget._label,
                      color: SmashColors.mainDecorations,
                      bold: true),
                ],
              ),
            ),
          )),
    );
  }
}

class PicturesWidget extends StatefulWidget {
  final _itemMap;
  final String _label;
  final dynamic _position;
  final int _noteId;
  final bool fromGallery;
  final AFormhelper formHelper;
  final bool _isReadOnly;

  PicturesWidget(this._noteId, this._itemMap, this._label, this._position,
      this.formHelper, this._isReadOnly,
      {this.fromGallery = false});

  @override
  PicturesWidgetState createState() => PicturesWidgetState();
}

class PicturesWidgetState extends State<PicturesWidget> {
  List<String> imageSplit = [];

  Future<List<Widget>> getThumbnails(BuildContext context) async {
    return await widget.formHelper
        .getThumbnailsFromDb(context, widget._itemMap, imageSplit);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: getThumbnails(context),
      builder: (BuildContext context, AsyncSnapshot<List<Widget>> snapshot) {
        switch (snapshot.connectionState) {
          case ConnectionState.none:
          case ConnectionState.waiting:
            return Center(
                child: SmashCircularProgress(label: "Loading pictures..."));
          default:
            if (snapshot.hasError) {
              return new Text(
                'Error: ${snapshot.error}',
                style: TextStyle(
                    color: SmashColors.mainSelection,
                    fontWeight: FontWeight.bold),
              );
            } else {
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    widget._isReadOnly
                        ? Container()
                        : FlatButton(
                            onPressed: () async {
                              String value = await widget.formHelper
                                  .takePictureForForms(
                                      context,
                                      widget._noteId,
                                      widget._position,
                                      widget.fromGallery,
                                      imageSplit);
                              if (value != null) {
                                setState(() {
                                  widget._itemMap[TAG_VALUE] = value;
                                });
                              }
                            },
                            child: Center(
                              child: Padding(
                                padding: SmashUI.defaultPadding(),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: <Widget>[
                                    Padding(
                                      padding: SmashUI.defaultRigthPadding(),
                                      child: Icon(
                                        Icons.camera_alt,
                                        color: SmashColors.mainDecorations,
                                      ),
                                    ),
                                    SmashUI.normalText(
                                        widget.fromGallery
                                            ? "Load image"
                                            : "Take a picture",
                                        color: SmashColors.mainDecorations,
                                        bold: true),
                                  ],
                                ),
                              ),
                            )),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: snapshot.data != null ? snapshot.data : [],
                      ),
                    ),
                  ],
                ),
              );
            }
        }
      },
    );
  }
}
