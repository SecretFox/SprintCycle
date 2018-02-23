import com.GameInterface.Game.CharacterBase;
import com.GameInterface.Game.Character;
import com.Utils.Signal;
import mx.utils.Delegate;
import com.Utils.Archive;
import com.GameInterface.Lore;
import com.GameInterface.SpellBase;
import com.GameInterface.Input;

class com.fox.SprintCycle.SprintCycle {

	private var speedyMounts:Object;
	private var mountlist:Array;
	private var nextMount:Number;
	private var player:Character;
	private var Speedboosts:Object;
	static var sprintSignal:Signal;

	public static function main(swfRoot:MovieClip):Void {
		var mod = new SprintCycle(swfRoot);
		swfRoot.onLoad  = function() { mod.Load(); };
		swfRoot.onUnload  = function() { mod.Unload();};
		swfRoot.OnModuleActivated = function(config:Archive) { mod.LoadConfig(config);};
		swfRoot.OnModuleDeactivated = function() { return mod.SaveConfig(); };
	}

	private function inList(id) {
		return speedyMounts[string(id)];
	}
	
	public function Unload() {
		player.SignalBuffAdded.Disconnect(IsBoost, this);
		sprintSignal.Disconnect(UseMount, this);
	}

	public function Load() {
		sprintSignal = new Signal();
		sprintSignal.Connect(UseMount, this);
		var mounts = Lore.GetMountTree();
		mountlist = new Array()
		for (var children in mounts["m_Children"]) {
			if (!mounts["m_Children"][children]["m_Locked"]) {
				var id = mounts["m_Children"][children]["m_Id"];
				if (inList(id)){
					mountlist.push(id);
				}
			}
		}
		mountlist.sort(Array.NUMERIC);
		RegisterHotkey(_global.Enums.InputCommand.e_InputCommand_Debug_MouseWorldPos, "com.fox.SprintCycle.SprintCycle.SendSprintSignal");
		player = new Character(CharacterBase.GetClientCharID());
		player.SignalBuffAdded.Connect(IsBoost, this);
		
		//Buffs
		Speedboosts = new Object();
		Speedboosts["9356708"] = true;
		Speedboosts["9114716"] = true;
		Speedboosts["9338105"] = true;
		Speedboosts["9253164"] = true;
		Speedboosts["9258408"] = true;
		
		//ID's for mounts that have speed boosts
		speedyMounts = new Object();
		speedyMounts["10153"] = true;
		speedyMounts["10516"] = true;
		speedyMounts["9330"] = true;
		speedyMounts["10437"] = true;
	}

	public static function SendSprintSignal() {
		sprintSignal.Emit();
	}

	private function IsBoost(buff) {
		if (Speedboosts[string(buff)]) {
			nextMount += 1;
			if (nextMount > mountlist.length - 1) nextMount = 0;
		}
	}

	private function UseMount() {
		var sprinting:Boolean = false;
		//is there more elegant way to check if player is sprinting?
		for (var i in player.m_InvisibleBuffList) {
			if (player.m_InvisibleBuffList[i].indexOf("Sprint") !=-1) {
				sprinting = true;
				break;
			}
		}
		//If player is threatened we shouldnt turn off sprint
		if (!player.IsThreatened()) {
			//already sprinting, switch to walk and then apply mount
			if (sprinting ) {
				SpellBase.SummonMountFromTag();
				setTimeout(Delegate.create(this, function() {
					SpellBase.SummonMountFromTag(this.mountlist[this.nextMount]);
				}), 100);
			//not sprinting,straight to sprinting
			} else if (!sprinting) {
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
		nextMount = Number(config.FindEntry("SprintCycle_NextMount", 0));
	}

	public function SaveConfig():Archive {
		var archive: Archive = new Archive();
		archive.AddEntry("SprintCycle_NextMount", nextMount);
		return archive
	}

	public function SprintCycle(swfRoot: MovieClip) {}
}