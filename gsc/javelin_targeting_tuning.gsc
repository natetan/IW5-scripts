/*
    Standalone Javelin targeting: shorter lock delay and ground minimum range.
    Preserve stock sampling, sight checks, vehicle perks, and missile behavior.
*/

main()
{
    setdvarifuninitialized( "fun_mode_javelin_targeting_enable", 1 );
    setdvarifuninitialized( "fun_mode_javelin_lock_time_ms", 575 );
    setdvarifuninitialized( "fun_mode_javelin_min_target_distance", 550 );

    if ( !getdvarint( "fun_mode_javelin_targeting_enable" ) )
        return;

    replacefunc(
        maps\mp\_javelin::javelinusageloop,
        ::tunedJavelinUsageLoop
    );
    replacefunc(
        maps\mp\_javelin::targetpointtooclose,
        ::tunedTargetPointTooClose
    );
}

tunedTargetPointTooClose( point )
{
    return distance( self.origin, point ) <
        getdvarfloat( "fun_mode_javelin_min_target_distance" );
}

// Stock keeps lock time local to this loop, shared by ground and vehicle paths.
// Retain the state machine; replace only its hard-coded lock duration.
tunedJavelinUsageLoop()
{
    self endon( "death" );
    self endon( "disconnect" );
    self endon( "faux_spawn" );
    var_0 = getdvarint( "fun_mode_javelin_lock_time_ms" );
    var_1 = 25;
    var_2 = 100;
    var_3 = 400;
    var_4 = 12;
    var_5 = 0;
    var_6 = 0;
    self.javelintarget = undefined;
    maps\mp\_javelin::initjavelinusage();

    for (;;)
    {
        wait 0.05;
        var_7 = 0;

        if ( getdvar( "missileDebugDraw" ) == "1" )
            var_7 = 1;

        var_8 = 0;

        if ( getdvar( "missileDebugText" ) == "1" )
            var_8 = 1;

        var_9 = self getcurrentweapon();

        if ( !issubstr( var_9, "javelin" ) || maps\mp\_utility::isemped() )
        {
            maps\mp\_javelin::resetjavelinlocking();
            continue;
        }

        if ( self playerads() < 0.95 )
        {
            var_6 = gettime();
            maps\mp\_javelin::resetjavelinlocking();
            continue;
        }

        self.javelinuseentered = 1;

        if ( !isdefined( self.javelinstage ) )
            self.javelinstage = 1;

        if ( self.javelinstage == 1 )
        {
            var_10 = maps\mp\_stinger::gettargetlist();

            if ( var_10.size != 0 )
            {
                var_11 = [];

                foreach ( var_13 in var_10 )
                {
                    var_14 = self worldpointinreticle_circle( var_13.origin, 65, 40 );

                    if ( var_14 )
                        var_11[var_11.size] = var_13;
                }

                if ( var_11.size != 0 )
                {
                    var_16 = sortbydistance( var_11, self.origin );

                    if ( !maps\mp\_javelin::vehiclelocksighttest( var_16[0] ) )
                        continue;

                    if ( var_8 )
                    {

                    }

                    self.javelintarget = var_16[0];

                    if ( !isdefined( self.javelinlockstarttime ) )
                        self.javelinlockstarttime = gettime();

                    self.javelinstage = 2;
                    self.javelinlostsightlinetime = 0;
                    maps\mp\_javelin::javelinlockvehicle( var_0 );
                    self.javelinstage = 1;
                    continue;
                }
            }

            if ( maps\mp\_javelin::lockmissespassedthreshold() )
            {
                maps\mp\_javelin::resetjavelinlocking();
                continue;
            }

            var_17 = gettime() - var_6;

            if ( var_17 < var_2 )
                continue;

            var_17 = gettime() - var_5;

            if ( var_17 < var_1 )
                continue;

            var_5 = gettime();
            var_21 = maps\mp\_javelin::eyetraceforward();

            if ( !isdefined( var_21 ) )
            {
                maps\mp\_javelin::lockmissesincr();
                continue;
            }

            if ( maps\mp\_javelin::targetpointtooclose( var_21[0] ) )
            {
                self weaponlocktargettooclose( 1 );
                continue;
            }
            else
                self weaponlocktargettooclose( 0 );

            if ( isdefined( self.javelinpoints ) )
            {
                var_22 = averagepoint( self.javelinpoints );
                var_23 = distance( var_22, var_21[0] );

                if ( var_23 > var_3 )
                {
                    maps\mp\_javelin::lockmissesincr();
                    continue;
                }
            }
            else
            {
                self.javelinpoints = [];
                self.javelinnormals = [];
            }

            self.javelinpoints[self.javelinpoints.size] = var_21[0];
            self.javelinnormals[self.javelinnormals.size] = var_21[1];
            maps\mp\_javelin::lockmissesreset();

            if ( self.javelinpoints.size < var_4 )
                continue;

            self.javelintargetpoint = averagepoint( self.javelinpoints );
            self.javelintargetnormal = averagenormal( self.javelinnormals );
            self.javelinlockmisses = undefined;
            self.javelinpoints = undefined;
            self.javelinnormals = undefined;
            self.javelinlockstarttime = gettime();
            self weaponlockstart( self.javelintargetpoint );
            thread maps\mp\_javelin::looplocalseeksound( "javelin_clu_aquiring_lock", 0.6 );
            self.javelinstage = 2;
        }

        if ( self.javelinstage == 2 )
        {
            var_14 = self worldpointinreticle_circle( self.javelintargetpoint, 65, 45 );

            if ( !var_14 )
            {
                maps\mp\_javelin::resetjavelinlocking();
                continue;
            }

            if ( maps\mp\_javelin::targetpointtooclose( self.javelintargetpoint ) )
                self weaponlocktargettooclose( 1 );
            else
                self weaponlocktargettooclose( 0 );

            var_17 = gettime() - self.javelinlockstarttime;

            if ( var_17 < var_0 )
                continue;

            self weaponlockfinalize( self.javelintargetpoint, ( 0.0, 0.0, 0.0 ), 1 );
            self notify( "stop_lockon_sound" );
            self playlocalsound( "javelin_clu_lock" );
            self.javelinstage = 3;
        }

        if ( self.javelinstage == 3 )
        {
            var_14 = self worldpointinreticle_circle( self.javelintargetpoint, 65, 45 );

            if ( !var_14 )
            {
                maps\mp\_javelin::resetjavelinlocking();
                continue;
            }

            if ( maps\mp\_javelin::targetpointtooclose( self.javelintargetpoint ) )
                self weaponlocktargettooclose( 1 );
            else
                self weaponlocktargettooclose( 0 );

            continue;
        }
    }
}
