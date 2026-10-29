#include maps\mp\_animatedmodels;

/*
    Animated Model Metadata Guard - IW5 / Plutonium

    Some custom maps contain an "animated_model" entity whose model is not
    registered in level.anim_prop_models. The stock function indexes that
    missing model entry directly and emits a runtime error during map load.
    Preserve the stock animation path for valid entities and leave malformed
    props static instead.
*/

main()
{
    // Plutonium auto-loads loose scripts; fun_mode owns initialization order.
}

Configure()
{
    ReplaceFunc(
        maps\mp\_animatedmodels::animatemodel,
        ::AnimateModelGuarded
    );
}

AnimateModelGuarded()
{
    if (IsDefined(self.animation))
    {
        animation = self.animation;
    }
    else
    {
        if (
            !IsDefined(self.model) ||
            !IsDefined(level.anim_prop_models) ||
            !IsDefined(level.anim_prop_models[self.model])
        )
        {
            return;
        }

        animationNames = GetArrayKeys(level.anim_prop_models[self.model]);

        if (!IsDefined(animationNames) || animationNames.size <= 0)
        {
            return;
        }

        animationName = animationNames[RandomInt(animationNames.size)];
        animation = level.anim_prop_models[self.model][animationName];
    }

    if (!IsDefined(animation))
    {
        return;
    }

    self ScriptModelPlayAnim(animation);
    self WillNeverChange();
}
