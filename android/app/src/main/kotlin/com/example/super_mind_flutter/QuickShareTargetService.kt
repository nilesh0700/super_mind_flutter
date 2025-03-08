package com.example.super_mind_flutter

import android.content.ComponentName
import android.content.IntentFilter
import android.graphics.drawable.Icon
import android.os.Bundle
import android.service.chooser.ChooserTarget
import android.service.chooser.ChooserTargetService
import android.content.Intent

class QuickShareTargetService : ChooserTargetService() {
    override fun onGetChooserTargets(
        targetActivityName: ComponentName,
        matchedFilter: IntentFilter
    ): List<ChooserTarget> {
        val targets = ArrayList<ChooserTarget>()
        
        // Create a direct share target for quick sharing
        val componentName = ComponentName(packageName, QuickShareActivity::class.java.name)
        val icon = Icon.createWithResource(this, R.mipmap.ic_launcher)
        
        // Add a target for "Quick Save"
        targets.add(
            ChooserTarget(
                "Quick Save",
                icon,
                0.9f,
                componentName,
                Bundle()
            )
        )
        
        return targets
    }
} 