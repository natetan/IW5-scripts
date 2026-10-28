#include common_scripts\_destructible;

/*
    Destructible Sound Guard - IW5 / Plutonium

    Some map destructible definitions reference an undefined, empty, or
    unavailable sound alias. Preserve the stock positioned-sound behavior but
    ignore aliases the current map did not load.
*/

main()
{
    // Plutonium auto-loads loose scripts; fun_mode owns initialization order.
}

Configure()
{
    ReplaceFunc(
        common_scripts\_destructible::play_sound,
        ::DestructiblePlaySoundGuarded
    );
}

DestructiblePlaySoundGuarded(soundAlias, tagName)
{
    if (
        !IsDefined(soundAlias) ||
        soundAlias == "" ||
        !SoundExists(soundAlias)
    )
    {
        return;
    }

    if (IsDefined(tagName))
    {
        soundOrigin = Spawn("script_origin", self GetTagOrigin(tagName));
        soundOrigin Hide();
        soundOrigin LinkTo(
            self,
            tagName,
            (0.0, 0.0, 0.0),
            (0.0, 0.0, 0.0)
        );
    }
    else
    {
        soundOrigin = Spawn("script_origin", (0.0, 0.0, 0.0));
        soundOrigin Hide();
        soundOrigin.origin = self.origin;
        soundOrigin.angles = self.angles;
        soundOrigin LinkTo(self);
    }

    soundOrigin PlaySound(soundAlias);
    wait 5.0;

    if (IsDefined(soundOrigin))
    {
        soundOrigin Delete();
    }
}
