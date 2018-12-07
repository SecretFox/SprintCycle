import com.GameInterface.DistributedValue;
import com.GameInterface.GUIModuleIF;
import com.GameInterface.Game.BuffData;
import com.GameInterface.Game.CharacterBase;
import com.GameInterface.Game.Character;
import com.GameInterface.LoreBase;
import com.GameInterface.Utils;
import com.Utils.Signal;
import mx.utils.Delegate;
import com.Utils.Archive;
import com.GameInterface.Lore;
import com.GameInterface.SpellBase;
import com.GameInterface.Input;

class com.fox.SprintCycle.SprintCycle {
	private var m_player:Character;

	static var sprintSignal:Signal;
	private var ApplySprintTimeout;
	private var ownedSpeedMounts:Array;
	private var ownedMounts:Array;
	private var ownedFavorites:Array;
	private var nextMount:Number;
	private var petWindow:DistributedValue;
	private var LockIfThreatened:DistributedValue;

	//sprint 1-6
	private var SPRINT_BUFFS:Array = [7481588, 7758936, 7758937, 7758938, 9114480, 9115262];
	//speed demon, Arachnoid, Gilded, Turbojet, Flightless
	private var SPRINT_MOUNTS:Array = [10153, 10516, 9330, 10437, 9432];
	//nitro, web, gallop, full thrust, gallop
	private var SPEED_BUFFS:Array = [9114716, 9356708, 9253164, 9338105, 9258408];

	public static function main(swfRoot:MovieClip):Void {
		var mod = new SprintCycle(swfRoot);
		swfRoot.onLoad  = function() { mod.Load(); };
		swfRoot.onUnload  = function() { mod.Unload();};
		swfRoot.OnModuleActivated = function(config:Archive) { mod.LoadConfig(config);};
		swfRoot.OnModuleDeactivated = function() { return mod.SaveConfig(); };
	}

	public function SprintCycle(swfRoot: MovieClip) {
		sprintSignal = new Signal();
		petWindow = DistributedValue.Create("petInventory_window");
		LockIfThreatened = DistributedValue.Create("SprintCycle_LockIfThreatened");
	}

	public function Load() {
		GetMounts();
		RegisterHotkey(_global.Enums.InputCommand.e_InputCommand_Movement_SprintToggle, "com.fox.SprintCycle.SprintCycle.SendSprintSignal");
		m_player = new Character(CharacterBase.GetClientCharID());
		m_player.SignalBuffAdded.Connect(IsBoost, this);
		sprintSignal.Connect(UseMount, this);
		petWindow.SignalChanged.Connect(PetWindowOpened, this);
		PetWindowOpened(petWindow);
	}

	public function Unload() {
		m_player.SignalBuffAdded.Disconnect(IsBoost, this);
		sprintSignal.Disconnect(UseMount, this);
		petWindow.SignalChanged.Disconnect(PetWindowOpened, this);
	}

	public function LoadConfig(config: Archive) {
		nextMount = Number(config.FindEntry("NextMount", 0));
		LockIfThreatened.SetValue(config.FindEntry("Lock", false));
	}

	public function SaveConfig():Archive {
		var archive: Archive = new Archive();
		archive.AddEntry("NextMount", nextMount);
		archive.AddEntry("Lock", LockIfThreatened.GetValue());
		return archive
	}

	private function inList(list, id) {
		for (var i in list) {
			if (list[i] == id) {
				return true;
			}
		}
		return false;
	}

	private function GetMounts() {
		var m_RootNode = Lore.GetMountTree();
		var allNodes:Array = m_RootNode.m_Children;
		ownedFavorites = new Array();
		ownedSpeedMounts = new Array();
		ownedMounts = new Array();
		var m_FavoriteTags = GetMountArchieveEntry("Favorites", 1);
		for (var i = 0; i < allNodes.length; i++) {
			if (Utils.GetGameTweak("HideMount_" + allNodes[i].m_Id) == 0) {
				var isFavorite:Boolean = false;
				for (var j = 0; j < m_FavoriteTags.length; j++) {
					if (m_FavoriteTags[j] == allNodes[i].m_Id) {
						isFavorite = true;
					}
				}
				if (!LoreBase.IsLocked(allNodes[i].m_Id)) {
					if (isFavorite) {
						ownedFavorites.push(allNodes[i]);
					} else {
						ownedMounts.push(allNodes[i]);
					}
					if (inList(SPRINT_MOUNTS, allNodes[i].m_Id)) {
						ownedSpeedMounts.push(allNodes[i].m_Id);
					}
				}
			}
		}
		ownedMounts = ownedFavorites.concat(ownedMounts);
		ownedSpeedMounts.sort(Array.NUMERIC);
	}

	private function GetMountArchieveEntry(entry:String,type) {
		var petModule:GUIModuleIF = GUIModuleIF.FindModuleIF("PetInventory");
		var petconfig:Archive = petModule.LoadConfig();
		if (!type) return petconfig.FindEntry(entry, 0);
		else return petconfig.FindEntryArray(entry);
	}

	private function AddSprintCycle() {
		if (_root.petinventory.m_Window.m_ButtonBar._selectedIndex == 0) {
			if (!_root.petinventory.m_Window.m_Content.m_EquipDropdown) {
				setTimeout(Delegate.create(this, AddSprintCycle), 100);
			} else {
				if (_root.petinventory.m_Window.m_Content.m_EquipDropdown.dataProvider.length == 3) {
					_root.petinventory.m_Window.m_Content.m_EquipDropdown.dataProvider.push("SprintCycle");
				}
				if (GetMountArchieveEntry("EquipStyle") == 3) {
					_root.petinventory.m_Window.m_Content.m_EquipDropdown.selectedIndex = 3;
				}
			}
		}
	}

	private function TabSelected(event:Object) {
		var tabIndex = (event != undefined && event.index != undefined) ? event.index : 0;
		if (tabIndex == 0) {
			AddSprintCycle();
		}
	}

	private function PetWindowOpened(dv:DistributedValue) {
		if (dv.GetValue()) {
			if (!_root.petinventory.m_Window.m_ButtonBar.dataProvider) {
				setTimeout(Delegate.create(this, PetWindowOpened), 100, dv);
			} else {
				_root.petinventory.m_Window.m_ButtonBar.addEventListener("change", this, "TabSelected");
				if (_root.petinventory.m_Window.m_ButtonBar.selectedIndex == 0) {
					AddSprintCycle();
				}
			}
		}
	}

	private function IsSprinting() {
		for (var i in m_player.m_InvisibleBuffList) {
			var buff:BuffData = m_player.m_InvisibleBuffList[i];
			if (inList(SPRINT_BUFFS,buff.m_BuffId))return true
			}
		return false
	}

	public static function SendSprintSignal() {
		sprintSignal.Emit();
	}

	private function IsBoost(buff) {
		if (inList(SPEED_BUFFS,buff)) {
			nextMount++;
			if (!ownedSpeedMounts[nextMount]) nextMount = 0;
		}
	}

	private function GetRandomMount(fav:Boolean) {
		if (!fav){
			return ownedMounts[Math.floor(Math.random() * ownedMounts.length)];  
		}else{
			return ownedFavorites[Math.floor(Math.random() * ownedFavorites.length)];  
		}

	}

	private function UseMount() {
		if (IsSprinting()) {
			if (!m_player.IsThreatened() || !LockIfThreatened.GetValue()) {
				SpellBase.SummonMountFromTag();
			}
			return
		}
		
		var mode = GetMountArchieveEntry("EquipStyle");
		
		switch (mode) {
			case 0:
				SpellBase.SummonMountFromTag(GetMountArchieveEntry("SelectedMount"));
				break
			case 1:
				SpellBase.SummonMountFromTag(GetRandomMount(false));
				break
			case 2:
				SpellBase.SummonMountFromTag(GetRandomMount(true));
				break
			case 3:
				SpellBase.SummonMountFromTag(ownedSpeedMounts[nextMount])
		}
	}

	private function RegisterHotkey(hotkey:Number, func:String) {
		Input.RegisterHotkey(hotkey, "", _global.Enums.Hotkey.eHotkeyDown, 0);
		Input.RegisterHotkey(hotkey, "", _global.Enums.Hotkey.eHotkeyUp, 0);
		Input.RegisterHotkey(hotkey, func, _global.Enums.Hotkey.eHotkeyDown, 0);
	}
}