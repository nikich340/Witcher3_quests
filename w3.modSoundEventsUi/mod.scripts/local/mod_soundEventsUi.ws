
function modCreate_SoundEventsUi() : CModSoundEventsUi {
    // do nothing besides creating and returning of mod class!
    return new CModSoundEventsUi in thePlayer;
}

// ----------------------------------------------------------------------------
class CModSoundEventsUiList extends CModUiFilteredList {

    public function initList() {
		var data: C2dArray;
        var i: int;
		var col0, cat1, cat2, cat3, id, caption : String;

        data = LoadCSV("dlc/dlcsoundeventsui/data/sound_events_list.csv");

        items.Clear();
		NTR_notify("Loaded from csv: " + data.GetNumRows());
        // csv: CAT1;CAT2;CAT3;id;caption
        for (i = 0; i < data.GetNumRows(); i += 1) {
            col0 = data.GetValueAt(0, i);
            cat1 = data.GetValueAt(1, i);
            cat2 = data.GetValueAt(2, i);
            cat3 = data.GetValueAt(3, i);
            id = data.GetValueAt(4, i);
            caption = data.GetValueAt(5, i);
			
			LogChannel('CModSoundEventsUiList', "cat1 [" + cat1 + "], cat2 [" + cat2 + "], cat3 [" + cat3 + "], id [" + id + "], caption [" + caption + "]");
			
            items.PushBack(SModUiCategorizedListItem(
                id,
                caption,
                cat1,
                cat2,
                cat3
            ));
        }
    }

}
// ----------------------------------------------------------------------------
// callback for generic ui list which will call example mod back
class CModSoundEventsUiListCallback extends IModUiEditableListCallback {
    public var callback: CModSoundEventsUi;

    public function OnOpened() { callback.OnUpdateView(); }

    public function OnInputEnd(inputString: String) { callback.OnInputEnd(inputString); }

    public function OnInputCancel() { callback.OnInputCancel(); }

    public function OnClosed() { delete listMenuRef; }

    public function OnSelected(optionName: String) { callback.OnSelected(optionName); }
}
// ----------------------------------------------------------------------------
statemachine class CModSoundEventsUi extends CMod {
    default modName = 'SoundEventsUi';
    default modAuthor = "nikich340, rmemr";
    default modUrl = "http://www.nexusmods.com/witcher3/mods/5070/";
    default modVersion = '1.0';

    default logLevel = MLOG_DEBUG;

    protected var view: CModSoundEventsUiListCallback;

    protected var listProvider: CModSoundEventsUiList;
	//protected var modSoundEventsUtil: CRadishModUtils;

    // ------------------------------------------------------------------------
    public function init() {
        super.init();

        // prepare view callback wiring and set labels
        view = new CModSoundEventsUiListCallback in this;
        view.callback = this;
        view.title = "Sound events UI";   // title currently unused (missing swf element for now)
        view.statsLabel = "Sound events";  // used for showing number of seen elements

        // load example data into list provider
        listProvider = new CModSoundEventsUiList in this;
        listProvider.initList();
		//modSoundEventsUtil = createModEnvUtil();

        // simple dummy hotkey binding for menu (reusing vanilla actions just for this example)
        // bind some other keys to test properly...
        // for a sane usage a new inputcontext should be started when menu is
        // opened and restored after it is closed
        // selection works either with mouse or space/enter
		
        //theInput.RegisterListener(this, 'OnOpenMenu', 'SteelSword');
        theInput.RegisterListener(this, 'OnFilter', 'SoundEventsUi_SetFilter');
        theInput.RegisterListener(this, 'OnResetFilter', 'SoundEventsUi_ResetFilter');
        theInput.RegisterListener(this, 'OnReset', 'SoundEventsUi_Reset');
        theInput.RegisterListener(this, 'OnQuit', 'SoundEventsUi_Quit');
        theInput.RegisterListener(this, 'OnCategoryUp', 'SoundEventsUi_ListCategoryUp');
        theInput.RegisterListener(this, 'OnReset', 'SoundEventsUi_Reset');
    }
	/*private function createModEnvUtil() : CRadishModUtils {
        var entity : CEntity;
        var template : CEntityTemplate;

        template = (CEntityTemplate)LoadResource("dlc\modtemplates\radishseeds\radish_modutils.w2ent", true);
        entity = theGame.CreateEntity(template,
                thePlayer.GetWorldPosition(), thePlayer.GetWorldRotation());

        return (CRadishModUtils)entity;
    }*/
	private function saveGameplaySettings() {
		/*if (modSoundEventsUtil) {
			modSoundEventsUtil.freezeTime();
			modSoundEventsUtil.deactivateHud();
		}*/

        // stop envui breakage if enemies attack
        thePlayer.SetTemporaryAttitudeGroup('q104_avallach_friendly_to_all', AGP_Default);
		thePlayer.SetImmortalityMode( AIM_Immortal, AIC_Combat );
		thePlayer.SetImmortalityMode( AIM_Immortal, AIC_Default );
		thePlayer.SetImmortalityMode( AIM_Immortal, AIC_Fistfight );
		thePlayer.SetImmortalityMode( AIM_Immortal, AIC_IsAttackableByPlayer );
		//SetTimeScaleQuest(0.01f);
    }
    // ------------------------------------------------------------------------
    private function restoreGameplaySettings() {
        thePlayer.ResetTemporaryAttitudeGroup(AGP_Default);
		thePlayer.SetImmortalityMode( AIM_None, AIC_Combat );
		thePlayer.SetImmortalityMode( AIM_None, AIC_Default );
		thePlayer.SetImmortalityMode( AIM_None, AIC_Fistfight );
		thePlayer.SetImmortalityMode( AIM_None, AIC_IsAttackableByPlayer );
		//SetTimeScaleQuest(1.0f);
		
		/*if (modSoundEventsUtil) {
			modSoundEventsUtil.unfreezeTime();
			modSoundEventsUtil.reactivateHud();
		}*/
    }
	// ------------------------------------------------------------------------
    public function openMenu() {
		saveGameplaySettings();
		FactsAdd('SoundEventsUi_active', 1);
		theSound.EnableMusicDebug(true);
		theInput.StoreContext('MOD_SoundEventsUi');
        theGame.RequestMenu('ListView', view);
    }
	
	public function playSoundEvent(listItemId : String) {
		var eventName, bankName, areaName : String;
		
		bankName = StrBeforeFirst(listItemId, ":");
		eventName = StrAfterFirst(listItemId, ":");
		NTR_notify("Play id [" + listItemId + "] ev [" + eventName + "] bnk [" + bankName + "]");
		
		if ( !theSound.SoundIsBankLoaded(bankName) ) {
			theSound.SoundLoadBank(bankName, true);
		}
		if ( StrContains(bankName, "music") ) {
			switch (bankName) {
				case "music_toussaint.bnk":
					theSound.InitializeAreaMusic( (EAreaName)AN_Dlc_Bob );
					break;
				case "music_skellige.bnk":
					theSound.InitializeAreaMusic( AN_Skellige_ArdSkellig );
					break;
				default:
					theSound.InitializeAreaMusic( AN_Undefined );
					break;
			}
			theSound.SoundEvent(eventName);
		} else {
			//theSound.SoundEvent(eventName);
			thePlayer.SoundEvent(eventName);
		}
	}
	
	// -----------------------------------------------------------------------
	event OnQuit(action: SInputAction) {
        if (IsPressed(action)) {
			FactsAdd('SoundEventsUi_active', -1);
			theSound.EnableMusicDebug(false);
			theInput.RestoreContext('MOD_SoundEventsUi', true);
			restoreGameplaySettings();
        }
    }
    // ------------------------------------------------------------------------
    // called by user action to open menu
    event OnOpenMenu(action: SInputAction) {
        // open only on action start
        if (IsPressed(action)) {
            openMenu();
        }
    }
	
	event OnReset(action: SInputAction) {
        // open only on action start
        if (IsPressed(action)) {
            listProvider.resetWildcardFilter();
			view.listMenuRef.resetEditField();
			
			listProvider.clearLowestSelectedCategory();
			listProvider.clearLowestSelectedCategory();
			listProvider.clearLowestSelectedCategory();

			updateView();
        }
    }

    // called by user action to start filter input
    event OnFilter(action: SInputAction) {
        if (!view.listMenuRef.isEditActive() && IsPressed(action)) {

            view.listMenuRef.startInputMode(
                //GetLocStringByKeyExt("MyModFilter"),
                "Filter List",
                listProvider.getWildcardFilter());
        }
    }
	
    // called by user action to reset currently set filter
    event OnResetFilter() {
        listProvider.resetWildcardFilter();
        view.listMenuRef.resetEditField();

        updateView();
    }

    // called by user action to go one opened category up
    event OnCategoryUp(action: SInputAction) {
        if (IsPressed(action)) {
            listProvider.clearLowestSelectedCategory();
            updateView();
        }
    }
    // ------------------------------------------------------------------------
    // -- called by listview
    // called if user exits edit mode in list
    event OnInputCancel() {
        theGame.GetGuiManager().ShowNotification("edit canceled");

        view.listMenuRef.resetEditField();
        updateView();
    }

    // called when user ends edit (return pressed)
    event OnInputEnd(inputString: String) {
        if (inputString == "") {
            OnResetFilter();
        } else {
            // Note: filter field is not removed to indicate the current filter
            listProvider.setWildcardFilter(inputString);
            updateView();
        }
    }

    // called when list item was selected
    event OnSelected(listItemId: String) {
        // listprovider opens a category if a category was selected otherwise
        // returns true (meaning a "real" item was selected)
        if (listProvider.setSelection(listItemId, true)) {
            playSoundEvent(listItemId);			
        }
        updateView();
    }

    // called when list menu opens first time
    event OnUpdateView() {
        var wildcard: String;
        // Note: if search filter is active show the wildcard to indicate the
        // current filter
        wildcard = listProvider.getWildcardFilter();
        if (wildcard != "") {
            view.listMenuRef.setInputFieldData(
                //GetLocStringByKeyExt("MyModFilter"),
                "Filter List",
                wildcard);
        }
        updateView();
    }
    // ------------------------------------------------------------------------
    protected function updateView() {
        // set updated list data and render in listview
        view.listMenuRef.setListData(
            listProvider.getFilteredList(),
            listProvider.getMatchingItemCount(),
            // number of items without filtering
            listProvider.getTotalCount());

        view.listMenuRef.updateView();
    }
}
// ----------------------------------------------------------------------------

exec function soundui() {
	var isActive : int;
	var mod : CModSoundEventsUi;
	isActive = FactsQuerySum("SoundEventsUi_active");
	if (!isActive) {
		mod = modCreate_SoundEventsUi();
		mod.init();
		mod.openMenu();
	} else {
		NTR_notify("Already active!!");
	}
}