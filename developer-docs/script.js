document.addEventListener('DOMContentLoaded',function(){
    const sidebar=document.querySelector('.sidebar');
    const menuToggle=document.querySelector('.menu-toggle');
    const navLinks=document.querySelectorAll('.nav-link');
    const sections=document.querySelectorAll('.doc-section');

    if(menuToggle){
        menuToggle.addEventListener('click',function(){
            sidebar.classList.toggle('open');
        });
    }

    document.addEventListener('click',function(e){
        if(window.innerWidth<=1024){
            if(!sidebar.contains(e.target)&&!menuToggle.contains(e.target)){
                sidebar.classList.remove('open');
            }
        }
    });

    navLinks.forEach(link=>{
        link.addEventListener('click',function(){
            if(window.innerWidth<=1024){
                sidebar.classList.remove('open');
            }
        });
    });

    const observerOptions={
        root:null,
        rootMargin:'-80px 0px -70% 0px',
        threshold:0
    };

    const observer=new IntersectionObserver(function(entries){
        entries.forEach(entry=>{
            if(entry.isIntersecting){
                const id=entry.target.getAttribute('id');
                navLinks.forEach(link=>{
                    link.classList.remove('active');
                    if(link.getAttribute('href')==='#'+id){
                        link.classList.add('active');
                    }
                });
            }
        });
    },observerOptions);

    sections.forEach(section=>{
        observer.observe(section);
    });

    document.querySelectorAll('a[href^="#"]').forEach(anchor=>{
        anchor.addEventListener('click',function(e){
            e.preventDefault();
            const target=document.querySelector(this.getAttribute('href'));
            if(target){
                const offset=80;
                const targetPosition=target.getBoundingClientRect().top+window.pageYOffset-offset;
                window.scrollTo({top:targetPosition,behavior:'smooth'});
            }
        });
    });

    const copyButtons=document.querySelectorAll('.copy-btn');
    copyButtons.forEach(btn=>{
        btn.addEventListener('click',function(){
            const codeBlock=this.closest('.code-block');
            const code=codeBlock.querySelector('code');
            const text=code.innerText;

            navigator.clipboard.writeText(text).then(()=>{
                const originalText=this.innerText;
                this.innerText='Copied!';
                this.style.color='var(--green)';
                setTimeout(()=>{
                    this.innerText=originalText;
                    this.style.color='';
                },2000);
            }).catch(()=>{
                this.innerText='Failed';
                setTimeout(()=>{
                    this.innerText='Copy';
                },2000);
            });
        });
    });

    const infoCards=document.querySelectorAll('.info-card');
    const archLayers=document.querySelectorAll('.arch-layer');
    const featureItems=document.querySelectorAll('.feature-item');
    const treeItems=document.querySelectorAll('.tree-item');

    const fadeObserver=new IntersectionObserver(function(entries){
        entries.forEach(entry=>{
            if(entry.isIntersecting){
                entry.target.style.opacity='1';
                entry.target.style.transform='translateY(0)';
            }
        });
    },{threshold:0.1});

    [...infoCards,...archLayers,...featureItems].forEach(el=>{
        el.style.opacity='0';
        el.style.transform='translateY(20px)';
        el.style.transition='opacity 0.5s ease, transform 0.5s ease';
        fadeObserver.observe(el);
    });

    treeItems.forEach((item,index)=>{
        item.style.opacity='0';
        item.style.transform='translateX(-10px)';
        item.style.transition='opacity 0.3s ease, transform 0.3s ease';
        item.style.transitionDelay=(index*0.03)+'s';
    });

    const treeObserver=new IntersectionObserver(function(entries){
        entries.forEach(entry=>{
            if(entry.isIntersecting){
                const items=entry.target.querySelectorAll('.tree-item');
                items.forEach(item=>{
                    item.style.opacity='1';
                    item.style.transform='translateX(0)';
                });
            }
        });
    },{threshold:0.1});

    const fileTree=document.querySelector('.file-tree');
    if(fileTree){
        treeObserver.observe(fileTree);
    }

    const flowSteps=document.querySelectorAll('.flow-step');
    const flowConnectors=document.querySelectorAll('.flow-connector');

    flowSteps.forEach((step,index)=>{
        step.style.opacity='0';
        step.style.transform='translateX(-20px)';
        step.style.transition='opacity 0.4s ease, transform 0.4s ease';
        step.style.transitionDelay=(index*0.15)+'s';
    });

    flowConnectors.forEach((conn,index)=>{
        conn.style.opacity='0';
        conn.style.height='0';
        conn.style.transition='opacity 0.3s ease, height 0.3s ease';
        conn.style.transitionDelay=(index*0.15+0.1)+'s';
    });

    const flowDiagram=document.querySelector('.flow-diagram');
    if(flowDiagram){
        const flowObserver=new IntersectionObserver(function(entries){
            entries.forEach(entry=>{
                if(entry.isIntersecting){
                    flowSteps.forEach(step=>{
                        step.style.opacity='1';
                        step.style.transform='translateX(0)';
                    });
                    flowConnectors.forEach(conn=>{
                        conn.style.opacity='1';
                        conn.style.height='20px';
                    });
                }
            });
        },{threshold:0.2});
        flowObserver.observe(flowDiagram);
    }

    const stateItems=document.querySelectorAll('.state-item');
    stateItems.forEach((item,index)=>{
        item.style.opacity='0';
        item.style.transform='scale(0.95)';
        item.style.transition='opacity 0.3s ease, transform 0.3s ease';
        item.style.transitionDelay=(index*0.05)+'s';
    });

    const stateVars=document.querySelector('.state-vars');
    if(stateVars){
        const stateObserver=new IntersectionObserver(function(entries){
            entries.forEach(entry=>{
                if(entry.isIntersecting){
                    stateItems.forEach(item=>{
                        item.style.opacity='1';
                        item.style.transform='scale(1)';
                    });
                }
            });
        },{threshold:0.2});
        stateObserver.observe(stateVars);
    }

    const compItems=document.querySelectorAll('.comp-item');
    compItems.forEach((item,index)=>{
        item.style.opacity='0';
        item.style.transform='translateY(10px)';
        item.style.transition='opacity 0.3s ease, transform 0.3s ease';
        item.style.transitionDelay=(index*0.08)+'s';
    });

    const componentTree=document.querySelector('.component-tree');
    if(componentTree){
        const compObserver=new IntersectionObserver(function(entries){
            entries.forEach(entry=>{
                if(entry.isIntersecting){
                    compItems.forEach(item=>{
                        item.style.opacity='1';
                        item.style.transform='translateY(0)';
                    });
                }
            });
        },{threshold:0.2});
        compObserver.observe(componentTree);
    }

    const colorSwatches=document.querySelectorAll('.color-swatch');
    colorSwatches.forEach(swatch=>{
        swatch.addEventListener('click',function(){
            const color=this.style.background;
            const match=color.match(/rgb\((\d+),\s*(\d+),\s*(\d+)\)/);
            if(match){
                const hex='#'+[match[1],match[2],match[3]].map(x=>{
                    const h=parseInt(x).toString(16);
                    return h.length===1?'0'+h:h;
                }).join('');
                navigator.clipboard.writeText(hex);
            }else{
                const code=this.parentElement.querySelector('code');
                if(code){
                    navigator.clipboard.writeText(code.innerText);
                }
            }
            this.style.transform='scale(0.9)';
            setTimeout(()=>{
                this.style.transform='scale(1)';
            },150);
        });
        swatch.style.cursor='pointer';
        swatch.style.transition='transform 0.15s ease';
    });

    const tableRows=document.querySelectorAll('.table-row');
    tableRows.forEach(row=>{
        row.addEventListener('mouseenter',function(){
            this.style.background='var(--bg-elevated)';
        });
        row.addEventListener('mouseleave',function(){
            this.style.background='';
        });
    });

    const topBar=document.querySelector('.top-bar');
    let lastScroll=0;
    window.addEventListener('scroll',function(){
        const currentScroll=window.pageYOffset;
        if(currentScroll>100){
            topBar.style.boxShadow='0 2px 20px rgba(0,0,0,0.3)';
        }else{
            topBar.style.boxShadow='none';
        }
        lastScroll=currentScroll;
    });

    const codeBlocks=document.querySelectorAll('.code-block pre');
    codeBlocks.forEach(block=>{
        block.addEventListener('dblclick',function(){
            const selection=window.getSelection();
            const range=document.createRange();
            range.selectNodeContents(this.querySelector('code'));
            selection.removeAllRanges();
            selection.addRange(range);
        });
    });

    const seqParticipants=document.querySelectorAll('.participant');
    seqParticipants.forEach((p,index)=>{
        p.style.opacity='0';
        p.style.transform='translateY(-10px)';
        p.style.transition='opacity 0.4s ease, transform 0.4s ease';
        p.style.transitionDelay=(index*0.1)+'s';
    });

    const seqMsgs=document.querySelectorAll('.seq-msg');
    seqMsgs.forEach((msg,index)=>{
        msg.style.opacity='0';
        msg.style.transition='opacity 0.3s ease';
        msg.style.transitionDelay=(0.5+index*0.1)+'s';
    });

    const seqDiagram=document.querySelector('.sequence-diagram');
    if(seqDiagram){
        const seqObserver=new IntersectionObserver(function(entries){
            entries.forEach(entry=>{
                if(entry.isIntersecting){
                    seqParticipants.forEach(p=>{
                        p.style.opacity='1';
                        p.style.transform='translateY(0)';
                    });
                    seqMsgs.forEach(msg=>{
                        msg.style.opacity='1';
                    });
                }
            });
        },{threshold:0.2});
        seqObserver.observe(seqDiagram);
    }
});
