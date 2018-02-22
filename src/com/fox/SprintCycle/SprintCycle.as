import com.GameInterface.Game.CharacterBase;
import com.GameInterface.Game.Character;
import com.Utils.Signal;
import mx.utils.Delegate;
import com.Utils.Archive;
import com.GameInterface.Lore;
import com.GameInterface.SpellBase;
import com.GameInterface.Input;
import com.GameInterface.UtilsBase;
import com.GameInterface.DistributedValue;

class com.fox.SprintCycle.SprintCycle{
	
	private var speedyMounts = new Array(10153, 10516, 9330, 10437);
	private var mountlist:Array;
	private var nextMount:Number;
	private var player:Character;
	private var Speedboosts:Object;
	static var sprintSignal:Signal;
	
	public static function main(swfRoot:MovieClip):Void{
		var bicycle = new SprintCycle(swfRoot);
		swfRoot.onLoad  = function() { bicycle.Init();};
		swfRoot.OnModuleActivated = function(config:Archive) { bicycle.LoadConfig(config);};
		swfRoot.OnModuleDeactivated = function() { return bicycle.SaveConfig(); };
	}
	
	private function inList(id,list){
		for (var i:Number = 0; i < list.length; i++){
			if (id == list[i])return true
		}
		return false
	}
	
	private function Init(){
		sprintSignal = new Signal();
		sprintSignal.Connect(UseMount, this);
		var mounts = Lore.GetMountTree();
		mountlist = new Array()
		for (var children in mounts["m_Children"]){
				if (!mounts["m_Children"][children]["m_Locked"]){
					var id = mounts["m_Children"][children]["m_Id"];
					if (inList(id, speedyMounts)) mountlist.push(id);
				}
		}
		mountlist.sort(Array.NUMERIC);
		RegisterHotkey(_global.Enums.InputCommand.e_InputCommand_Debug_MouseWorldPos, "com.fox.SprintCycle.SprintCycle.SendSprintSignal");
		player = new Character(CharacterBase.GetClientCharID());
		player.SignalBuffAdded.Connect(IsBoost, this);
		Speedboosts = new Object();
		Speedboosts["9356708"] = true;
		Speedboosts["9114716"] = true;
		Speedboosts["9338105"] = true;
		Speedboosts["9253164"] = true;
		Speedboosts["9258408"] = true;
		
	}
	
	public static function SendSprintSignal(){
		sprintSignal.Emit();
	}
	
	private function IsBoost(buff){
		// Last two are Unicorns gallops,one of them is incorrect becauses i don't have one for testing
		if (Speedboosts[string(buff)]){
			nextMount += 1;
			if (nextMount > mountlist.length - 1) nextMount = 0;
		}
	}

	private function UseMount(){
		var sprinting:Boolean = false;
		for (var i in player.m_InvisibleBuffList){
			if (player.m_InvisibleBuffList[i].indexOf("Sprint") !=-1){
				sprinting = true;
				break;
			}
		}
		if(!player.IsThreatened()){
			if (sprinting ){
				SpellBase.SummonMountFromTag();
				setTimeout(Delegate.create(this, function(){
					SpellBase.SummonMountFromTag(this.mountlist[this.nextMount]);
				}),100);
			}else if (!sprinting){
				SpellBase.SummonMountFromTag(mountlist[nextMount])
			}
		}
	}
	
	private function RegisterHotkey(hotkey:Number, func:String){
		Input.RegisterHotkey(hotkey, "", _global.Enums.Hotkey.eHotkeyDown, 0);
		Input.RegisterHotkey(hotkey, "", _global.Enums.Hotkey.eHotkeyUp, 0);
		Input.RegisterHotkey(hotkey, func, _global.Enums.Hotkey.eHotkeyDown, 0);
	}
	
	public function LoadConfig(config: Archive){
		nextMount = Number(config.FindEntry("SprintCycle_NextMount", 0));
	}
	
	public function SaveConfig():Archive{
		var archive: Archive = new Archive();
		archive.AddEntry("SprintCycle_NextMount", nextMount);
		return archive
	}
	
    public function SprintCycle(swfRoot: MovieClip){}
}