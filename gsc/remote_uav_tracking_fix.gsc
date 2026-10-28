#include maps\mp\killstreaks\_remoteuav;

/*
    Recon Drone Tracking Guard - IW5 / Plutonium

    Preserves stock range behavior while tolerating maps that do not provide
    usable remote_uav_range or airstrikeheight metadata.
*/

main()
{
    // Plutonium auto-loads loose scripts; fun_mode owns initialization order.
}

Configure()
{
    ReplaceFunc(
        maps\mp\killstreaks\_remoteuav::remoteuav_in_range,
        ::RemoteUavInRangeGuarded
    );
}

RemoteUavInRangeGuarded()
{
    inHeliProximity = (
        IsDefined(self.inheliproximity) &&
        self.inheliproximity
    );

    if (IsDefined(self.rangetrigger))
    {
        if (!self IsTouching(self.rangetrigger) && !inHeliProximity)
        {
            return 1;
        }

        return 0;
    }

    maxDistance = 12800;

    if (IsDefined(self.maxdistance))
    {
        maxDistance = self.maxdistance;
    }

    withinHeight = true;

    if (IsDefined(self.maxheight))
    {
        withinHeight = self.origin[2] < self.maxheight;
    }

    if (
        Distance2D(self.origin, level.mapcenter) < maxDistance &&
        withinHeight &&
        !inHeliProximity
    )
    {
        return 1;
    }

    return 0;
}
