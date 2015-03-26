#AtomPair

Remote pairing within the [Atom.IO](http://atom.io) text editor, powered by Pusher.

##How Do I Get Started?

###Install

First off, install Atom if you haven't already. Now type into your terminal:

    $ apm install atom-pair

Alternatively, go to the command palette via `command+shift+p` and go to `Install Packages and Themes`. Then search for and install `atom-pair`.

###Invite

You can either decide to pair on a blank slate, or on existing code. If you invite somebody to collaborate on existing code, they will see everything you can, and their syntax highlighting will be synchronized with yours.

As detailed below, there are two ways you can invite others. Given a [free](https://pusher.com/signup?utm_source=Reddit&utm_medium=Atom.io_Package_Page&utm_campaign=AtomPair) Sandbox plan, there will be a maximum of 20 collaborators per session.


####Basic Invitation

Hit `command+shift+p`, and in the command palette, hit `AtomPair: Start A New Pairing Session`.

You will be given a session ID, hit `command+c` and paste that to a friend.

![Basic Invite](https://raw.githubusercontent.com/pusher/atom-pair/blog_post/images/invite.gif)

####HipChat Invitation

The other way - one that we use quite often - is to invite collaborators over [HipChat](http://hipchat.com), a service for intra-company chat. You can sign up for a free account [here](https://www.hipchat.com/sign_up).

We wanted this partly as an easy way of giving collaborators a session ID, but also so that other members of the team could join in if they wanted to.

If you have admin privileges in a HipChat organization, go to your Package Settings (`⌘+,` -> 'Packages' -> 'atom-pair'). Enter your HipChat API key and the room you wish the invitation to be sent through.

Now, when you enter `AtomPair: Invite Over HipChat` and enter your collaborator's HipChat @mention_name in the command palette, they will receive an invitation with a session ID.

![HipChat Invite](https://raw.githubusercontent.com/pusher/atom-pair/blog_post/images/hipchat.jpg)

####Slack Invitation

If you use [Slack](https://slack.com/) instead of HipChat, we have you covered for that too.  It works pretty much the same way as the HipChat integration.  All you need to do is log into your Slack account and click "Configure Integrations" and configure an "Incoming Webhook".  It will ask you to choose a channel you want to post messages to, but this doesn't really matter too much, you will manually specify the channel or recipient when you send the invite.  Once you set up your integration, it will give you a "Webhook URL".  You'll need to copy this URL, and put it in your atom-pair configuration where it asks for a "WebHook URL for Slack Incoming Webhook Integration".

To send the invite, simply enter "AtomPair: Invite Over Slack" and enter either the channel you want to send the invite to _(#channel)_ or the person you want to send the invite to _(@person)_.  Once you do, all they have to do is join the session with the session ID and you'll be pair programming!

###Collaborate!

![Demo](https://raw.githubusercontent.com/pusher/atom-pair/blog_post/images/demo.gif)

Once your partner has a session ID, they should go to the command pallette and hit `AtomPair: Join a pairing session`, and enter the ID.

Once there are more than one of you in a session, your collaborators will be represented by a coloured marker in the gutter, which will changed position based on their selections and inputs.

To end a pairing session, go to `AtomPair: Disconnect`, and you will be disconnected from Pusher, and the file will be free for you to save.

##Free And Open For Everyone

Currently, you are given default Pusher credentials when you install the package, so that you can get started with as less friction as possible. Communication will take place over a randomly generated channel name. However, for improved security, we encourage you to [create a free account](https://pusher.com/signup?utm_source=Reddit&utm_medium=Atom.io_Package_Page&utm_campaign=AtomPair) and enter your own app key and app secret by going to your Package Settings. A free Sandbox plan should be more than enough for your pairing sessions.

###Contributing

Here is a current list of features:

* Text synchronization
* File-sharing
* HipChat invitations
* Slack invitations
* Synchronized syntax highlighting
* Collaborator visibility.

But if there are any features you find lacking, feel more than welcome to [get in touch](<mailto:jamie@pusher.com>).

## To Do

* Allow sharing of whole directories.
* Fix issues users have been having with snippets

## Credits

This project is owned and maintained by [@jpatel531](http://github.com/jpatel531), a developer at [Pusher](http://pusher.com).

Special thanks for contributing go to:

* [@snollygolly](http://github.com/snollygolly)
