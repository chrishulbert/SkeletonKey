Skeleton Key Password Manager with Dropbox
===
Are you one of those people who can't keep track of all their zillions of passwords? Are you sick of having to waste time on the I-forgot-my-password dance whenever you visit a website you can't remember your login for? Well, I made this app for people like you, to keep track of all your passwords, and hopefully make your life just a little bit easier.

Skeleton Key helps you keep track of your passwords. All your data is securely encrypted and optionally synced to Dropbox so that you can stay in sync between multiple iDevices. It is reasonably priced - a small cost for the full version with no monthly fees, as opposed to LastPass (monthly fees) and 1Password (high upfront cost). Tested by professional software testers, it is reliable for you to use with confidence.

FREE for the first week, as a gesture of goodwill towards early adopters! If you find that you like this app, please recommend it to friends. The more people download it, the more I'll be able to update it with all your future feature requests (eg Windows / Mac versions).

Your data is secured via a single master password (and optional access PIN for convenience), so that you only ever need to remember one password again. You can organise your items into customizable colour-coded groups to keep things organised just the way you like.

(Warning: technical paragraph alert!) Your data is securely encrypted using industry-standard technologies: your master password is transformed by PBKDF2 to create an AES256 key, which is used to encrypt all your data. Your password/PIN are also hashed with Bcrypt for verification purposes.

Initial setup
---
If you plan on syncing to Dropbox (highly recommended) then the first thing you should do after installing the app is to link to your Dropbox account. To do this, follow the initial prompts, or tap the settings icon (top left, shaped like a cog) and then tap Dropbox. If you've already got items saved on your Dropbox account from a different install of this app, it will pull them all down and ask you to enter your password.

After you've synced (or skipped this step, if you decide you won't want to), you then must set a master password. The app will ask you to set a master password automatically the first time you go to add an item, by pressing '+' on the top-right of the main screen.

If you wish, you can add a PIN so that you won't have to enter the master password every time you open the app. The PIN won't be synced, rather it'll be stored in the device's keychain. This keychain is secured by iOS, however you should be aware that it is technically hackable if your phone falls into the wrong hands. For this reason, I recommend you performing a remote wipe of your phone if you lose it. Using the master password has no known security issues like this.

How to use
---
From the main side of the app, you can see all your different groups represented as tabs at the bottom of the screen. To see the items inside those groups, tap the tab.

To add an item to a group, select that group/tab, and then press '+' on the top-right of the screen.

Adding a new item
---
When you're presented with the new item details screen, the first thing you want to do is set a name for the item. Tap the 'name' row to do this. The name would eg the name of a website whose password you need to remember.

After you've set the name, you can fill in the login and password fields as you wish by tapping their rows. You can swipe those rows to delete them if they're not appropriate for this item. You can then tap 'add new field' to add a custom-named field. Tap save to save it, which will immediately attempt to sync the new item to Dropbox.

Customizing groups
---
To customize your groups, first go to the settings page (tap the cog-shaped icon on the top left of the main screen). Then select 'Groups' to go to the groups editor.

To add a new group, tap '+' on the navigation bar. To delete a group or re-order them, tap 'edit'. To edit one of the groups, tap its name.

If you tap '+' to add a group, or tap an existing group, you will be taken to the 'Edit Group' screen. From here, you can change the name of the group, change the highlight color for its navigation bar, and change its tab bar icon.

Dropbox
---
Dropbox is a fantastic service for keeping track of your files across multiple computers, devices, etc, which are then accessible anywhere you are. It isn't necessary for this app, but it's highly recommended. [Get an account here](https://www.dropbox.com).

With the settings page, you can link this app to your Dropbox account and synchronize your files to your `Dropbox\Apps\SkeletonKey` folder. This is also very handy if you wish to share your service history files between two iPhones, or an iPad / iPod touch.

It is recommended that you link this app to Dropbox as the first thing you do when installing the app. Go to settings (top left button) and tap 'Dropbox' to link. All your data is automatically synced as soon as you open the app or make any data changes.

About
---
This app was created by Chris Hulbert from Splinter Software, in Sydney. I really hope you find it useful! Get in touch with any feature requests, or if you need further help: [chris.hulbert@gmail.com](mailto:chris.hulbert@gmail.com).

Credits
---

* Texture by [subtle patterns](http://subtlepatterns.com)
* Design by [Lauradesign](http://lauradesign.com.au)
* [YAMLKit](https://github.com/patrickt/yamlkit)
* [JFBCrypt](http://www.jayfuerstenberg.com/blog/bcrypt-in-objective-c)
* [AQToolkit](https://github.com/AlanQuatermain/aqtoolkit)
