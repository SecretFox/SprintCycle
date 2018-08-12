import com.GameInterface.Game.BuffData;
import com.GameInterface.Game.CharacterBase;
import com.GameInterface.Game.Character;
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
	private var mountlist:Array;
	private var nextMount:Number;
	
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
		var mounts = Lore.GetMountTree();
		mountlist = new Array()
		for (var children in mounts["m_Children"]) {
			if (!mounts["m_Children"][children]["m_Locked"]) {
				var id = mounts["m_Children"][children]["m_Id"];
				if (inList(SPRINT_MOUNTS, id)){
					mountlist.push(id);
				}
			}
		}
		mountlist.sort(Array.NUMERIC);
		RegisterHotkey(_global.Enums.InputCommand.e_InputCommand_Debug_MouseWorldPos, "com.fox.SprintCycle.SprintCycle.SendSprintSignal");
		m_player = new Character(CharacterBase.GetClientCharID());
		
	}
	
	private function inList(list, id) {
		for (var i in list){
			if (list[i] == id) return true;
		}
		return false;
	}
	
	private function IsSprinting(){
		for (var i in m_player.m_InvisibleBuffList){
			var buff:BuffData = m_player.m_InvisibleBuffList[i];
			if(inList(SPRINT_BUFFS,buff.m_BuffId))return true
		}
		return false
	}
	
	public function Unload() {
		m_player.SignalBuffAdded.Disconnect(IsBoost, this);
		sprintSignal.Disconnect(UseMount, this);
	}

	public function Load() {
		m_player.SignalBuffAdded.Connect(IsBoost, this);
		sprintSignal.Connect(UseMount, this);

	}

	public static function SendSprintSignal() {
		sprintSignal.Emit();
	}

	private function IsBoost(buff) {
		if (inList(SPEED_BUFFS,buff)) {
			nextMount++;
			if (!mountlist[nextMount]) nextMount = 0;
		}
	}

	private function UseMount() {
		//If player is threatened we shouldn't turn off sprint
		clearTimeout(ApplySprintTimeout);
		if (!m_player.IsThreatened()) {
			// Already sprinting, switch to walk and then apply mount
			if (IsSprinting()) {
				SpellBase.SummonMountFromTag();
				ApplySprintTimeout = setTimeout(Delegate.create(this, UseMount),100);
			//not sprinting,straight to sprinting
			} else {
				SpellBase.SummonMountFromTag(mountlist[nextMount])
			}
		}
	}

	private function RegisterHotkey(hotkey:Number, func:String) {
		Input.RegisterHotkey(hotkey, "", _global.Enums.Hotkey.eHotkeyDown, 0);
		Input.RegisterHotkey(hotkey, "", _global.Enums.Hotkey.eHotkeyUp, 0);
		Input.RegisterHotkey(hotkey, func, _global.Enums.Hotkey.eHotkeyDown, 0);
	}

	public function LoadConfig(config: Archive) {
		nextMount = Number(config.FindEntry("NextMount", 0));
	}

	public function SaveConfig():Archive {
		var archive: Archive = new Archive();
		archive.AddEntry("NextMount", nextMount);
		return archive
	}
}