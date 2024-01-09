package funkin.ui.debug;

import flixel.math.FlxPoint;
import flixel.FlxObject;
import flixel.FlxSprite;
import funkin.ui.MusicBeatSubState;
import funkin.ui.TextMenuList;
import funkin.ui.debug.charting.ChartEditorState;
import funkin.ui.MusicBeatSubState;
import funkin.util.logging.CrashHandler;
import flixel.addons.transition.FlxTransitionableState;

class DebugMenuSubState extends MusicBeatSubState
{
  var items:TextMenuList;

  /**
   * Camera focus point
   */
  var camFocusPoint:FlxObject;

  override function create():Void
  {
    FlxTransitionableState.skipNextTransIn = true;
    super.create();

    bgColor = 0x00000000;

    // Create an object for the camera to track.
    camFocusPoint = new FlxObject(0, 0);
    add(camFocusPoint);

    // Follow the camera focus as we scroll.
    FlxG.camera.follow(camFocusPoint, null, 0.06);

    // Create the green background.
    var menuBG = new FlxSprite().loadGraphic(Paths.image('menuDesat'));
    menuBG.color = 0xFF4CAF50;
    menuBG.setGraphicSize(Std.int(menuBG.width * 1.1));
    menuBG.updateHitbox();
    menuBG.screenCenter();
    menuBG.scrollFactor.set(0, 0);
    add(menuBG);

    // Create the list for menu items.
    items = new TextMenuList();
    // Move the camera when the menu is scrolled.
    items.onChange.add(onMenuChange);
    add(items);

    FlxTransitionableState.skipNextTransIn = true;

    // Create each menu item.
    // Call onMenuChange when the first item is created to move the camera .
    onMenuChange(createItem("CHART EDITOR", openChartEditor));
    createItem("Input Offset Testing", openInputOffsetTesting);
    createItem("ANIMATION EDITOR", openAnimationEditor);
    createItem("STAGE EDITOR", openStageEditor);
    createItem("TEST STICKERS", testStickers);
    #if sys
    createItem("OPEN CRASH LOG FOLDER", openLogFolder);
    #end
    FlxG.camera.focusOn(new FlxPoint(camFocusPoint.x, camFocusPoint.y));
    FlxG.camera.focusOn(new FlxPoint(camFocusPoint.x, camFocusPoint.y + 500));
  }

  function onMenuChange(selected:TextMenuItem)
  {
    camFocusPoint.setPosition(selected.x + selected.width / 2, selected.y + selected.height / 2);
  }

  override function update(elapsed:Float)
  {
    super.update(elapsed);

    if (controls.BACK)
    {
      FlxG.sound.play(Paths.sound('cancelMenu'));
      exitDebugMenu();
    }
  }

  function createItem(name:String, callback:Void->Void, fireInstantly = false)
  {
    var item = items.createItem(0, 100 + items.length * 100, name, BOLD, callback);
    item.fireInstantly = fireInstantly;
    item.screenCenter(X);
    return item;
  }

  function openChartEditor()
  {
    FlxG.switchState(new ChartEditorState());
  }

  function openInputOffsetTesting()
  {
    FlxG.switchState(new funkin.ui.debug.latency.LatencyState());
    trace('Input Offset Testing');
  }

  function openAnimationEditor()
  {
    FlxG.switchState(new funkin.ui.debug.anim.DebugBoundingState());
    trace('Animation Editor');
  }

  function testStickers()
  {
    openSubState(new funkin.ui.transition.StickerSubState());
    trace('opened stickers');
  }

  function openStageEditor()
  {
    trace('Stage Editor');
  }

  #if sys
  function openLogFolder()
  {
    #if windows
    Sys.command('explorer', [CrashHandler.LOG_FOLDER]);
    #elseif mac
    // mac could be fuckie with where the log folder is relative to the game file...
    // if this comment is still here... it means it has NOT been verified on mac yet!
    Sys.command('open', [CrashHandler.LOG_FOLDER]);
    #end

    // TODO: implement linux
    // some shit with xdg-open :thinking: emoji...
  }
  #end

  function exitDebugMenu()
  {
    // TODO: Add a transition?
    this.close();
  }
}
