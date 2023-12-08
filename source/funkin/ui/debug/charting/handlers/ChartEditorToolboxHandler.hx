package funkin.ui.debug.charting.handlers;

import funkin.play.stage.StageData.StageDataParser;
import funkin.play.stage.StageData;
import funkin.play.character.CharacterData;
import funkin.play.character.CharacterData.CharacterDataParser;
import haxe.ui.components.HorizontalSlider;
import haxe.ui.containers.TreeView;
import haxe.ui.containers.TreeViewNode;
import funkin.play.character.BaseCharacter.CharacterType;
import funkin.play.event.SongEvent;
import funkin.data.event.SongEventData;
import funkin.data.song.SongData.SongTimeChange;
import funkin.ui.debug.charting.commands.ChangeStartingBPMCommand;
import funkin.play.character.BaseCharacter.CharacterType;
import funkin.play.character.CharacterData;
import funkin.play.character.CharacterData.CharacterDataParser;
import funkin.play.event.SongEvent;
import funkin.play.song.SongSerializer;
import funkin.play.stage.StageData;
import funkin.play.stage.StageData.StageDataParser;
import haxe.ui.RuntimeComponentBuilder;
import funkin.ui.debug.charting.util.ChartEditorDropdowns;
import funkin.ui.haxeui.components.CharacterPlayer;
import funkin.util.FileUtil;
import haxe.ui.components.Button;
import haxe.ui.components.CheckBox;
import haxe.ui.components.DropDown;
import haxe.ui.components.HorizontalSlider;
import haxe.ui.components.Label;
import haxe.ui.components.NumberStepper;
import haxe.ui.components.Slider;
import haxe.ui.components.TextField;
import haxe.ui.containers.Box;
import haxe.ui.containers.dialogs.CollapsibleDialog;
import haxe.ui.containers.dialogs.Dialog.DialogButton;
import haxe.ui.containers.dialogs.Dialog.DialogEvent;
import haxe.ui.containers.Frame;
import haxe.ui.containers.Grid;
import haxe.ui.containers.TreeView;
import haxe.ui.containers.TreeViewNode;
import haxe.ui.core.Component;
import haxe.ui.data.ArrayDataSource;
import haxe.ui.events.UIEvent;

/**
 * Static functions which handle building themed UI elements for a provided ChartEditorState.
 */
@:nullSafety
@:access(funkin.ui.debug.charting.ChartEditorState)
class ChartEditorToolboxHandler
{
  public static function setToolboxState(state:ChartEditorState, id:String, shown:Bool):Void
  {
    if (shown)
    {
      showToolbox(state, id);
    }
    else
    {
      hideToolbox(state, id);
    }
  }

  public static function showToolbox(state:ChartEditorState, id:String):Void
  {
    var toolbox:Null<CollapsibleDialog> = state.activeToolboxes.get(id);

    if (toolbox == null) toolbox = initToolbox(state, id);

    if (toolbox != null)
    {
      toolbox.showDialog(false);

      state.playSound(Paths.sound('chartingSounds/openWindow'));

      switch (id)
      {
        case ChartEditorState.CHART_EDITOR_TOOLBOX_NOTEDATA_LAYOUT:
          onShowToolboxNoteData(state, toolbox);
        case ChartEditorState.CHART_EDITOR_TOOLBOX_EVENTDATA_LAYOUT:
          onShowToolboxEventData(state, toolbox);
        case ChartEditorState.CHART_EDITOR_TOOLBOX_DIFFICULTY_LAYOUT:
          onShowToolboxDifficulty(state, toolbox);
        case ChartEditorState.CHART_EDITOR_TOOLBOX_METADATA_LAYOUT:
          onShowToolboxMetadata(state, toolbox);
        case ChartEditorState.CHART_EDITOR_TOOLBOX_PLAYER_PREVIEW_LAYOUT:
          onShowToolboxPlayerPreview(state, toolbox);
        case ChartEditorState.CHART_EDITOR_TOOLBOX_OPPONENT_PREVIEW_LAYOUT:
          onShowToolboxOpponentPreview(state, toolbox);
        default:
          // This happens if you try to load an unknown layout.
          trace('ChartEditorToolboxHandler.showToolbox() - Unknown toolbox ID: $id');
      }
    }
    else
    {
      trace('ChartEditorToolboxHandler.showToolbox() - Could not retrieve toolbox: $id');
    }
  }

  public static function hideToolbox(state:ChartEditorState, id:String):Void
  {
    var toolbox:Null<CollapsibleDialog> = state.activeToolboxes.get(id);

    if (toolbox == null) toolbox = initToolbox(state, id);

    if (toolbox != null)
    {
      toolbox.hideDialog(DialogButton.CANCEL);

      state.playSound(Paths.sound('chartingSounds/exitWindow'));

      switch (id)
      {
        case ChartEditorState.CHART_EDITOR_TOOLBOX_NOTEDATA_LAYOUT:
          onHideToolboxNoteData(state, toolbox);
        case ChartEditorState.CHART_EDITOR_TOOLBOX_EVENTDATA_LAYOUT:
          onHideToolboxEventData(state, toolbox);
        case ChartEditorState.CHART_EDITOR_TOOLBOX_DIFFICULTY_LAYOUT:
          onHideToolboxDifficulty(state, toolbox);
        case ChartEditorState.CHART_EDITOR_TOOLBOX_METADATA_LAYOUT:
          onHideToolboxMetadata(state, toolbox);
        case ChartEditorState.CHART_EDITOR_TOOLBOX_PLAYER_PREVIEW_LAYOUT:
          onHideToolboxPlayerPreview(state, toolbox);
        case ChartEditorState.CHART_EDITOR_TOOLBOX_OPPONENT_PREVIEW_LAYOUT:
          onHideToolboxOpponentPreview(state, toolbox);
        default:
          // This happens if you try to load an unknown layout.
          trace('ChartEditorToolboxHandler.hideToolbox() - Unknown toolbox ID: $id');
      }
    }
    else
    {
      trace('ChartEditorToolboxHandler.hideToolbox() - Could not retrieve toolbox: $id');
    }
  }

  public static function rememberOpenToolboxes(state:ChartEditorState):Void {}

  public static function openRememberedToolboxes(state:ChartEditorState):Void {}

  public static function hideAllToolboxes(state:ChartEditorState):Void
  {
    for (toolbox in state.activeToolboxes.values())
    {
      toolbox.hideDialog(DialogButton.CANCEL);
    }
  }

  public static function minimizeToolbox(state:ChartEditorState, id:String):Void
  {
    var toolbox:Null<CollapsibleDialog> = state.activeToolboxes.get(id);

    if (toolbox == null) return;

    toolbox.minimized = true;
  }

  public static function maximizeToolbox(state:ChartEditorState, id:String):Void
  {
    var toolbox:Null<CollapsibleDialog> = state.activeToolboxes.get(id);

    if (toolbox == null) return;

    toolbox.minimized = false;
  }

  public static function initToolbox(state:ChartEditorState, id:String):Null<CollapsibleDialog>
  {
    var toolbox:Null<CollapsibleDialog> = null;
    switch (id)
    {
      case ChartEditorState.CHART_EDITOR_TOOLBOX_NOTEDATA_LAYOUT:
        toolbox = buildToolboxNoteDataLayout(state);
      case ChartEditorState.CHART_EDITOR_TOOLBOX_EVENTDATA_LAYOUT:
        toolbox = buildToolboxEventDataLayout(state);
      case ChartEditorState.CHART_EDITOR_TOOLBOX_DIFFICULTY_LAYOUT:
        toolbox = buildToolboxDifficultyLayout(state);
      case ChartEditorState.CHART_EDITOR_TOOLBOX_METADATA_LAYOUT:
        toolbox = buildToolboxMetadataLayout(state);
      case ChartEditorState.CHART_EDITOR_TOOLBOX_PLAYER_PREVIEW_LAYOUT:
        toolbox = buildToolboxPlayerPreviewLayout(state);
      case ChartEditorState.CHART_EDITOR_TOOLBOX_OPPONENT_PREVIEW_LAYOUT:
        toolbox = buildToolboxOpponentPreviewLayout(state);
      default:
        // This happens if you try to load an unknown layout.
        trace('ChartEditorToolboxHandler.initToolbox() - Unknown toolbox ID: $id');
        toolbox = null;
    }

    // This happens if the layout you try to load has a syntax error.
    if (toolbox == null) return null;

    // Make sure we can reuse the toolbox later.
    toolbox.destroyOnClose = false;
    state.activeToolboxes.set(id, toolbox);

    return toolbox;
  }

  /**
   * Retrieve a toolbox by its layout's asset ID.
   * @param state The ChartEditorState instance.
   * @param id The asset ID of the toolbox layout.
   * @return The toolbox.
   */
  public static function getToolbox(state:ChartEditorState, id:String):Null<CollapsibleDialog>
  {
    var toolbox:Null<CollapsibleDialog> = state.activeToolboxes.get(id);

    // Initialize the toolbox without showing it.
    if (toolbox == null) toolbox = initToolbox(state, id);

    if (toolbox == null) throw 'ChartEditorToolboxHandler.getToolbox() - Could not retrieve or build toolbox: $id';

    return toolbox;
  }

  static function buildToolboxNoteDataLayout(state:ChartEditorState):Null<CollapsibleDialog>
  {
    var toolbox:CollapsibleDialog = cast RuntimeComponentBuilder.fromAsset(ChartEditorState.CHART_EDITOR_TOOLBOX_NOTEDATA_LAYOUT);

    if (toolbox == null) return null;

    // Starting position.
    toolbox.x = 75;
    toolbox.y = 100;

    toolbox.onDialogClosed = function(event:DialogEvent) {
      state.menubarItemToggleToolboxNotes.selected = false;
    }

    var toolboxNotesNoteKind:Null<DropDown> = toolbox.findComponent('toolboxNotesNoteKind', DropDown);
    if (toolboxNotesNoteKind == null) throw 'ChartEditorToolboxHandler.buildToolboxNoteDataLayout() - Could not find toolboxNotesNoteKind component.';
    var toolboxNotesCustomKindLabel:Null<Label> = toolbox.findComponent('toolboxNotesCustomKindLabel', Label);
    if (toolboxNotesCustomKindLabel == null)
      throw 'ChartEditorToolboxHandler.buildToolboxNoteDataLayout() - Could not find toolboxNotesCustomKindLabel component.';
    var toolboxNotesCustomKind:Null<TextField> = toolbox.findComponent('toolboxNotesCustomKind', TextField);
    if (toolboxNotesCustomKind == null) throw 'ChartEditorToolboxHandler.buildToolboxNoteDataLayout() - Could not find toolboxNotesCustomKind component.';

    toolboxNotesNoteKind.onChange = function(event:UIEvent) {
      var isCustom:Bool = (event.data.id == '~CUSTOM~');

      if (isCustom)
      {
        toolboxNotesCustomKindLabel.hidden = false;
        toolboxNotesCustomKind.hidden = false;

        state.selectedNoteKind = toolboxNotesCustomKind.text;
      }
      else
      {
        toolboxNotesCustomKindLabel.hidden = true;
        toolboxNotesCustomKind.hidden = true;

        state.selectedNoteKind = event.data.id;
      }
    }

    toolboxNotesCustomKind.onChange = function(event:UIEvent) {
      state.selectedNoteKind = toolboxNotesCustomKind.text;
    }

    return toolbox;
  }

  static function onShowToolboxNoteData(state:ChartEditorState, toolbox:CollapsibleDialog):Void {}

  static function onHideToolboxNoteData(state:ChartEditorState, toolbox:CollapsibleDialog):Void {}

  static function buildToolboxEventDataLayout(state:ChartEditorState):Null<CollapsibleDialog>
  {
    var toolbox:CollapsibleDialog = cast RuntimeComponentBuilder.fromAsset(ChartEditorState.CHART_EDITOR_TOOLBOX_EVENTDATA_LAYOUT);

    if (toolbox == null) return null;

    // Starting position.
    toolbox.x = 100;
    toolbox.y = 150;

    toolbox.onDialogClosed = function(event:DialogEvent) {
      state.menubarItemToggleToolboxEvents.selected = false;
    }

    var toolboxEventsEventKind:Null<DropDown> = toolbox.findComponent('toolboxEventsEventKind', DropDown);
    if (toolboxEventsEventKind == null) throw 'ChartEditorToolboxHandler.buildToolboxEventDataLayout() - Could not find toolboxEventsEventKind component.';
    var toolboxEventsDataGrid:Null<Grid> = toolbox.findComponent('toolboxEventsDataGrid', Grid);
    if (toolboxEventsDataGrid == null) throw 'ChartEditorToolboxHandler.buildToolboxEventDataLayout() - Could not find toolboxEventsDataGrid component.';

    toolboxEventsEventKind.dataSource = new ArrayDataSource();

    var songEvents:Array<SongEvent> = SongEventParser.listEvents();

    for (event in songEvents)
    {
      toolboxEventsEventKind.dataSource.add({text: event.getTitle(), value: event.id});
    }

    toolboxEventsEventKind.onChange = function(event:UIEvent) {
      var eventType:String = event.data.value;

      trace('ChartEditorToolboxHandler.buildToolboxEventDataLayout() - Event type changed: $eventType');

      state.selectedEventKind = eventType;

      var schema:SongEventSchema = SongEventParser.getEventSchema(eventType);

      if (schema == null)
      {
        trace('ChartEditorToolboxHandler.buildToolboxEventDataLayout() - Unknown event kind: $eventType');
        return;
      }

      buildEventDataFormFromSchema(state, toolboxEventsDataGrid, schema);
    }
    toolboxEventsEventKind.value = state.selectedEventKind;

    return toolbox;
  }

  static function onShowToolboxEventData(state:ChartEditorState, toolbox:CollapsibleDialog):Void {}

  static function onHideToolboxEventData(state:ChartEditorState, toolbox:CollapsibleDialog):Void {}

  static function buildEventDataFormFromSchema(state:ChartEditorState, target:Box, schema:SongEventSchema):Void
  {
    trace(schema);
    // Clear the frame.
    target.removeAllComponents();

    state.selectedEventData = {};

    for (field in schema)
    {
      if (field == null) continue;

      // Add a label.
      var label:Label = new Label();
      label.text = field.title;
      label.verticalAlign = "center";
      target.addComponent(label);

      var input:Component;
      switch (field.type)
      {
        case INTEGER:
          var numberStepper:NumberStepper = new NumberStepper();
          numberStepper.id = field.name;
          numberStepper.step = field.step ?? 1.0;
          numberStepper.min = field.min ?? 0.0;
          numberStepper.max = field.max ?? 10.0;
          if (field.defaultValue != null) numberStepper.value = field.defaultValue;
          input = numberStepper;
        case FLOAT:
          var numberStepper:NumberStepper = new NumberStepper();
          numberStepper.id = field.name;
          numberStepper.step = field.step ?? 0.1;
          if (field.min != null) numberStepper.min = field.min;
          if (field.max != null) numberStepper.max = field.max;
          if (field.defaultValue != null) numberStepper.value = field.defaultValue;
          input = numberStepper;
        case BOOL:
          var checkBox:CheckBox = new CheckBox();
          checkBox.id = field.name;
          if (field.defaultValue != null) checkBox.selected = field.defaultValue;
          input = checkBox;
        case ENUM:
          var dropDown:DropDown = new DropDown();
          dropDown.id = field.name;
          dropDown.width = 200.0;
          dropDown.dataSource = new ArrayDataSource();

          if (field.keys == null) throw 'Field "${field.name}" is of Enum type but has no keys.';

          // Add entries to the dropdown.

          for (optionName in field.keys.keys())
          {
            var optionValue:Null<Dynamic> = field.keys.get(optionName);
            trace('$optionName : $optionValue');
            dropDown.dataSource.add({value: optionValue, text: optionName});
          }

          dropDown.value = field.defaultValue;

          input = dropDown;
        case STRING:
          input = new TextField();
          input.id = field.name;
          if (field.defaultValue != null) input.text = field.defaultValue;
        default:
          // Unknown type. Display a label so we know what it is.
          input = new Label();
          input.id = field.name;
          input.text = field.type;
      }

      target.addComponent(input);

      input.onChange = function(event:UIEvent) {
        var value = event.target.value;
        if (field.type == ENUM)
        {
          value = event.target.value.value;
        }
        trace('ChartEditorToolboxHandler.buildEventDataFormFromSchema() - ${event.target.id} = ${value}');

        if (value == null)
        {
          state.selectedEventData.remove(event.target.id);
        }
        else
        {
          state.selectedEventData.set(event.target.id, value);
        }
      }
    }
  }

  static function buildToolboxDifficultyLayout(state:ChartEditorState):Null<CollapsibleDialog>
  {
    var toolbox:CollapsibleDialog = cast RuntimeComponentBuilder.fromAsset(ChartEditorState.CHART_EDITOR_TOOLBOX_DIFFICULTY_LAYOUT);

    if (toolbox == null) return null;

    // Starting position.
    toolbox.x = 125;
    toolbox.y = 200;

    toolbox.onDialogClosed = function(event:UIEvent) {
      state.menubarItemToggleToolboxDifficulty.selected = false;
    }

    var difficultyToolboxAddVariation:Null<Button> = toolbox.findComponent('difficultyToolboxAddVariation', Button);
    if (difficultyToolboxAddVariation == null)
      throw 'ChartEditorToolboxHandler.buildToolboxDifficultyLayout() - Could not find difficultyToolboxAddVariation component.';
    var difficultyToolboxAddDifficulty:Null<Button> = toolbox.findComponent('difficultyToolboxAddDifficulty', Button);
    if (difficultyToolboxAddDifficulty == null)
      throw 'ChartEditorToolboxHandler.buildToolboxDifficultyLayout() - Could not find difficultyToolboxAddDifficulty component.';
    var difficultyToolboxSaveMetadata:Null<Button> = toolbox.findComponent('difficultyToolboxSaveMetadata', Button);
    if (difficultyToolboxSaveMetadata == null)
      throw 'ChartEditorToolboxHandler.buildToolboxDifficultyLayout() - Could not find difficultyToolboxSaveMetadata component.';
    var difficultyToolboxSaveChart:Null<Button> = toolbox.findComponent('difficultyToolboxSaveChart', Button);
    if (difficultyToolboxSaveChart == null)
      throw 'ChartEditorToolboxHandler.buildToolboxDifficultyLayout() - Could not find difficultyToolboxSaveChart component.';
    // var difficultyToolboxSaveAll:Null<Button> = toolbox.findComponent('difficultyToolboxSaveAll', Button);
    // if (difficultyToolboxSaveAll == null) throw 'ChartEditorToolboxHandler.buildToolboxDifficultyLayout() - Could not find difficultyToolboxSaveAll component.';
    var difficultyToolboxLoadMetadata:Null<Button> = toolbox.findComponent('difficultyToolboxLoadMetadata', Button);
    if (difficultyToolboxLoadMetadata == null)
      throw 'ChartEditorToolboxHandler.buildToolboxDifficultyLayout() - Could not find difficultyToolboxLoadMetadata component.';
    var difficultyToolboxLoadChart:Null<Button> = toolbox.findComponent('difficultyToolboxLoadChart', Button);
    if (difficultyToolboxLoadChart == null)
      throw 'ChartEditorToolboxHandler.buildToolboxDifficultyLayout() - Could not find difficultyToolboxLoadChart component.';

    difficultyToolboxAddVariation.onClick = function(_:UIEvent) {
      state.openAddVariationDialog(true);
    };

    difficultyToolboxAddDifficulty.onClick = function(_:UIEvent) {
      state.openAddDifficultyDialog(true);
    };

    difficultyToolboxSaveMetadata.onClick = function(_:UIEvent) {
      var vari:String = state.selectedVariation != Constants.DEFAULT_VARIATION ? '-${state.selectedVariation}' : '';
      FileUtil.writeFileReference('${state.currentSongId}$vari-metadata.json', state.currentSongMetadata.serialize());
    };

    difficultyToolboxSaveChart.onClick = function(_:UIEvent) {
      var vari:String = state.selectedVariation != Constants.DEFAULT_VARIATION ? '-${state.selectedVariation}' : '';
      FileUtil.writeFileReference('${state.currentSongId}$vari-chart.json', state.currentSongChartData.serialize());
    };

    difficultyToolboxLoadMetadata.onClick = function(_:UIEvent) {
      // Replace metadata for current variation.
      SongSerializer.importSongMetadataAsync(function(songMetadata) {
        state.currentSongMetadata = songMetadata;
      });
    };

    difficultyToolboxLoadChart.onClick = function(_:UIEvent) {
      // Replace chart data for current variation.
      SongSerializer.importSongChartDataAsync(function(songChartData) {
        state.currentSongChartData = songChartData;
        state.noteDisplayDirty = true;
      });
    };

    state.difficultySelectDirty = true;

    return toolbox;
  }

  static function onShowToolboxDifficulty(state:ChartEditorState, toolbox:CollapsibleDialog):Void
  {
    // Update the selected difficulty when reopening the toolbox.
    var treeView:Null<TreeView> = toolbox.findComponent('difficultyToolboxTree');
    if (treeView == null) return;

    var current = state.getCurrentTreeDifficultyNode(treeView);
    if (current == null) return;
    treeView.selectedNode = current;
    trace('selected node: ${treeView.selectedNode}');
  }

  static function onHideToolboxDifficulty(state:ChartEditorState, toolbox:CollapsibleDialog):Void {}

  static function buildToolboxMetadataLayout(state:ChartEditorState):Null<CollapsibleDialog>
  {
    var toolbox:CollapsibleDialog = cast RuntimeComponentBuilder.fromAsset(ChartEditorState.CHART_EDITOR_TOOLBOX_METADATA_LAYOUT);

    if (toolbox == null) return null;

    // Starting position.
    toolbox.x = 150;
    toolbox.y = 250;

    toolbox.onDialogClosed = function(event:UIEvent) {
      state.menubarItemToggleToolboxMetadata.selected = false;
    }

    var inputSongName:Null<TextField> = toolbox.findComponent('inputSongName', TextField);
    if (inputSongName == null) throw 'ChartEditorToolboxHandler.buildToolboxMetadataLayout() - Could not find inputSongName component.';
    inputSongName.onChange = function(event:UIEvent) {
      var valid:Bool = event.target.text != null && event.target.text != '';

      if (valid)
      {
        inputSongName.removeClass('invalid-value');
        state.currentSongMetadata.songName = event.target.text;
      }
      else
      {
        state.currentSongMetadata.songName = '';
      }
    };
    inputSongName.value = state.currentSongMetadata.songName;

    var inputSongArtist:Null<TextField> = toolbox.findComponent('inputSongArtist', TextField);
    if (inputSongArtist == null) throw 'ChartEditorToolboxHandler.buildToolboxMetadataLayout() - Could not find inputSongArtist component.';
    inputSongArtist.onChange = function(event:UIEvent) {
      var valid:Bool = event.target.text != null && event.target.text != '';

      if (valid)
      {
        inputSongArtist.removeClass('invalid-value');
        state.currentSongMetadata.artist = event.target.text;
      }
      else
      {
        state.currentSongMetadata.artist = '';
      }
    };
    inputSongArtist.value = state.currentSongMetadata.artist;

    var inputStage:Null<DropDown> = toolbox.findComponent('inputStage', DropDown);
    if (inputStage == null) throw 'ChartEditorToolboxHandler.buildToolboxMetadataLayout() - Could not find inputStage component.';
    inputStage.onChange = function(event:UIEvent) {
      var valid:Bool = event.data != null && event.data.id != null;

      if (valid)
      {
        state.currentSongMetadata.playData.stage = event.data.id;
      }
    };
    var startingValueStage = ChartEditorDropdowns.populateDropdownWithStages(inputStage, state.currentSongMetadata.playData.stage);
    inputStage.value = startingValueStage;

    var inputNoteStyle:Null<DropDown> = toolbox.findComponent('inputNoteStyle', DropDown);
    if (inputNoteStyle == null) throw 'ChartEditorToolboxHandler.buildToolboxMetadataLayout() - Could not find inputNoteStyle component.';
    inputNoteStyle.onChange = function(event:UIEvent) {
      if (event.data?.id == null) return;
      state.currentSongNoteStyle = event.data.id;
    };
    inputNoteStyle.value = state.currentSongNoteStyle;

    // By using this flag, we prevent the dropdown value from changing while it is being populated.

    var inputCharacterPlayer:Null<DropDown> = toolbox.findComponent('inputCharacterPlayer', DropDown);
    if (inputCharacterPlayer == null) throw 'ChartEditorToolboxHandler.buildToolboxMetadataLayout() - Could not find inputCharacterPlayer component.';
    inputCharacterPlayer.onChange = function(event:UIEvent) {
      if (event.data?.id == null) return;
      state.currentSongMetadata.playData.characters.player = event.data.id;
    };
    var startingValuePlayer = ChartEditorDropdowns.populateDropdownWithCharacters(inputCharacterPlayer, CharacterType.BF,
      state.currentSongMetadata.playData.characters.player);
    inputCharacterPlayer.value = startingValuePlayer;

    var inputCharacterOpponent:Null<DropDown> = toolbox.findComponent('inputCharacterOpponent', DropDown);
    if (inputCharacterOpponent == null) throw 'ChartEditorToolboxHandler.buildToolboxMetadataLayout() - Could not find inputCharacterOpponent component.';
    inputCharacterOpponent.onChange = function(event:UIEvent) {
      if (event.data?.id == null) return;
      state.currentSongMetadata.playData.characters.opponent = event.data.id;
    };
    var startingValueOpponent = ChartEditorDropdowns.populateDropdownWithCharacters(inputCharacterOpponent, CharacterType.DAD,
      state.currentSongMetadata.playData.characters.opponent);
    inputCharacterOpponent.value = startingValueOpponent;

    var inputCharacterGirlfriend:Null<DropDown> = toolbox.findComponent('inputCharacterGirlfriend', DropDown);
    if (inputCharacterGirlfriend == null) throw 'ChartEditorToolboxHandler.buildToolboxMetadataLayout() - Could not find inputCharacterGirlfriend component.';
    inputCharacterGirlfriend.onChange = function(event:UIEvent) {
      if (event.data?.id == null) return;
      state.currentSongMetadata.playData.characters.girlfriend = event.data.id == "none" ? "" : event.data.id;
    };
    var startingValueGirlfriend = ChartEditorDropdowns.populateDropdownWithCharacters(inputCharacterGirlfriend, CharacterType.GF,
      state.currentSongMetadata.playData.characters.girlfriend);
    inputCharacterGirlfriend.value = startingValueGirlfriend;

    var inputBPM:Null<NumberStepper> = toolbox.findComponent('inputBPM', NumberStepper);
    if (inputBPM == null) throw 'ChartEditorToolboxHandler.buildToolboxMetadataLayout() - Could not find inputBPM component.';
    inputBPM.onChange = function(event:UIEvent) {
      if (event.value == null || event.value <= 0) return;

      // Use a command so we can undo/redo this action.
      var startingBPM = state.currentSongMetadata.timeChanges[0].bpm;
      if (event.value != startingBPM)
      {
        state.performCommand(new ChangeStartingBPMCommand(event.value));
      }
    };
    inputBPM.value = state.currentSongMetadata.timeChanges[0].bpm;

    var inputOffsetInst:Null<NumberStepper> = toolbox.findComponent('inputOffsetInst', NumberStepper);
    if (inputOffsetInst == null) throw 'ChartEditorToolboxHandler.buildToolboxMetadataLayout() - Could not find inputOffsetInst component.';
    inputOffsetInst.onChange = function(event:UIEvent) {
      if (event.value == null) return;

      state.currentInstrumentalOffset = event.value;
      Conductor.instrumentalOffset = event.value;
      // Update song length.
      state.songLengthInMs = state.audioInstTrack?.length ?? 1000.0 + Conductor.instrumentalOffset;
    };
    inputOffsetInst.value = state.currentInstrumentalOffset;

    var inputOffsetVocal:Null<NumberStepper> = toolbox.findComponent('inputOffsetVocal', NumberStepper);
    if (inputOffsetVocal == null) throw 'ChartEditorToolboxHandler.buildToolboxMetadataLayout() - Could not find inputOffsetVocal component.';
    inputOffsetVocal.onChange = function(event:UIEvent) {
      if (event.value == null) return;

      state.currentSongMetadata.offsets.setVocalOffset(state.currentSongMetadata.playData.characters.player, event.value);
    };
    inputOffsetVocal.value = state.currentSongMetadata.offsets.getVocalOffset(state.currentSongMetadata.playData.characters.player);

    var labelScrollSpeed:Null<Label> = toolbox.findComponent('labelScrollSpeed', Label);
    if (labelScrollSpeed == null) throw 'ChartEditorToolboxHandler.buildToolboxMetadataLayout() - Could not find labelScrollSpeed component.';

    var inputScrollSpeed:Null<Slider> = toolbox.findComponent('inputScrollSpeed', Slider);
    if (inputScrollSpeed == null) throw 'ChartEditorToolboxHandler.buildToolboxMetadataLayout() - Could not find inputScrollSpeed component.';
    inputScrollSpeed.onChange = function(event:UIEvent) {
      var valid:Bool = event.target.value != null && event.target.value > 0;

      if (valid)
      {
        inputScrollSpeed.removeClass('invalid-value');
        state.currentSongChartScrollSpeed = event.target.value;
      }
      else
      {
        state.currentSongChartScrollSpeed = 1.0;
      }
      labelScrollSpeed.text = 'Scroll Speed: ${state.currentSongChartScrollSpeed}x';
    };
    inputScrollSpeed.value = state.currentSongChartScrollSpeed;
    labelScrollSpeed.text = 'Scroll Speed: ${state.currentSongChartScrollSpeed}x';

    var frameVariation:Null<Frame> = toolbox.findComponent('frameVariation', Frame);
    if (frameVariation == null) throw 'ChartEditorToolboxHandler.buildToolboxMetadataLayout() - Could not find frameVariation component.';
    frameVariation.text = 'Variation: ${state.selectedVariation.toTitleCase()}';

    var frameDifficulty:Null<Frame> = toolbox.findComponent('frameDifficulty', Frame);
    if (frameDifficulty == null) throw 'ChartEditorToolboxHandler.buildToolboxMetadataLayout() - Could not find frameDifficulty component.';
    frameDifficulty.text = 'Difficulty: ${state.selectedDifficulty.toTitleCase()}';

    return toolbox;
  }

  static function onShowToolboxMetadata(state:ChartEditorState, toolbox:CollapsibleDialog):Void
  {
    state.refreshMetadataToolbox();
  }

  static function onHideToolboxMetadata(state:ChartEditorState, toolbox:CollapsibleDialog):Void {}

  static function buildToolboxPlayerPreviewLayout(state:ChartEditorState):Null<CollapsibleDialog>
  {
    var toolbox:CollapsibleDialog = cast RuntimeComponentBuilder.fromAsset(ChartEditorState.CHART_EDITOR_TOOLBOX_PLAYER_PREVIEW_LAYOUT);

    if (toolbox == null) return null;

    // Starting position.
    toolbox.x = 200;
    toolbox.y = 350;

    toolbox.onDialogClosed = function(event:DialogEvent) {
      state.menubarItemToggleToolboxPlayerPreview.selected = false;
    }

    var charPlayer:Null<CharacterPlayer> = toolbox.findComponent('charPlayer');
    if (charPlayer == null) throw 'ChartEditorToolboxHandler.buildToolboxPlayerPreviewLayout() - Could not find charPlayer component.';
    // TODO: We need to implement character swapping in ChartEditorState.
    charPlayer.loadCharacter('bf');
    charPlayer.characterType = CharacterType.BF;
    charPlayer.flip = true;
    charPlayer.targetScale = 0.5;

    return toolbox;
  }

  static function onShowToolboxPlayerPreview(state:ChartEditorState, toolbox:CollapsibleDialog):Void {}

  static function onHideToolboxPlayerPreview(state:ChartEditorState, toolbox:CollapsibleDialog):Void {}

  static function buildToolboxOpponentPreviewLayout(state:ChartEditorState):Null<CollapsibleDialog>
  {
    var toolbox:CollapsibleDialog = cast RuntimeComponentBuilder.fromAsset(ChartEditorState.CHART_EDITOR_TOOLBOX_OPPONENT_PREVIEW_LAYOUT);

    if (toolbox == null) return null;

    // Starting position.
    toolbox.x = 200;
    toolbox.y = 350;

    toolbox.onDialogClosed = (event:DialogEvent) -> {
      state.menubarItemToggleToolboxOpponentPreview.selected = false;
    }

    var charPlayer:Null<CharacterPlayer> = toolbox.findComponent('charPlayer');
    if (charPlayer == null) throw 'ChartEditorToolboxHandler.buildToolboxOpponentPreviewLayout() - Could not find charPlayer component.';
    // TODO: We need to implement character swapping in ChartEditorState.
    charPlayer.loadCharacter('dad');
    charPlayer.characterType = CharacterType.DAD;
    charPlayer.flip = false;
    charPlayer.targetScale = 0.5;

    return toolbox;
  }

  static function onShowToolboxOpponentPreview(state:ChartEditorState, toolbox:CollapsibleDialog):Void {}

  static function onHideToolboxOpponentPreview(state:ChartEditorState, toolbox:CollapsibleDialog):Void {}
}
